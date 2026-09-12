import base64
import io
import json
import os
import unittest
from unittest.mock import patch
from urllib.error import HTTPError
import app
from fastapi.testclient import TestClient


class RecognitionTests(unittest.TestCase):
    def test_no_key_does_not_call_provider(self):
        with patch.dict(os.environ, {'SILICONFLOW_API_KEY': ''}), patch('app.urlopen') as call:
            self.assertEqual(app.recognize({})[0], 503)
            call.assert_not_called()

    def test_missing_fields_remain_unknown(self):
        result = app.validate_result({'medicines': [{'name': '药品', 'source_text': '药品'}]})
        self.assertIsNone(result['medicines'][0]['dose'])
        self.assertIsNone(result['medicines'][0]['specification'])

    def test_rejects_missing_evidence_and_bad_types(self):
        for row in [{'name': '药品'}, {'source_text': '原文', 'dose': 2}]:
            with self.assertRaises(ValueError):
                app.validate_result({'medicines': [row]})

    def test_invalid_image_does_not_call_provider(self):
        with patch.dict(os.environ, {'SILICONFLOW_API_KEY': 'test'}), patch('app.urlopen') as call:
            self.assertEqual(app.recognize({'image': 'bad!'})[0], 400)
            call.assert_not_called()

    def test_mocked_provider_success_and_truncation(self):
        image = {'image': base64.b64encode(b'\xff\xd8\xfftest').decode()}
        for reason, expected in [('stop', 200), ('length', 502)]:
            payload = {'choices': [{'finish_reason': reason, 'message': {'content': json.dumps({'medicines': [{'name': '示例', 'source_text': '示例'}], 'warnings': []})}}]}
            with patch.dict(os.environ, {'SILICONFLOW_API_KEY': 'test'}), patch('app.urlopen', return_value=io.BytesIO(json.dumps(payload).encode())) as call:
                status, result = app.recognize(image)
                self.assertEqual(status, expected)
                sent = json.loads(call.call_args.args[0].data)
                self.assertEqual(sent['model'], 'Qwen/Qwen3-VL-32B-Instruct')
                if status == 200:
                    self.assertIsNone(result['medicines'][0]['frequency'])

    def test_auth_error_is_sanitized(self):
        with patch.dict(os.environ, {'SILICONFLOW_API_KEY': 'test'}), patch('app.urlopen', side_effect=HTTPError('url', 401, 'secret-body', None, None)):
            status, result = app.recognize({'image': base64.b64encode(b'\xff\xd8\xfftest').decode()})
            self.assertEqual(status, 502)
            self.assertNotIn('secret-body', result['error'])

if __name__ == '__main__':
    unittest.main()

class BillingTests(unittest.TestCase):
    def test_insufficient_balance_has_actionable_message(self):
        with patch.dict(os.environ, {'SILICONFLOW_API_KEY': 'test'}), patch('app.urlopen', side_effect=HTTPError('url', 402, 'billing', None, None)):
            status, result = app.recognize({'image': base64.b64encode(b'\xff\xd8\xfftest').decode()})
            self.assertEqual(status, 502)
            self.assertIn('余额不足', result['error'])

class ModelSelectionTests(unittest.TestCase):
    def test_selected_model_forwarded(self):
        result = {'choices': [{'finish_reason': 'stop', 'message': {'content': '{"medicines":[],"warnings":[]}'}}]}
        with patch.dict(os.environ, {'SILICONFLOW_API_KEY': 'test'}), patch('app.urlopen', return_value=io.BytesIO(json.dumps(result).encode())) as call:
            status, _ = app.recognize({'image': base64.b64encode(b'\xff\xd8\xfftest').decode(), 'model': app.ALLOWED_MODELS[1]})
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(call.call_args.args[0].data)['model'], app.ALLOWED_MODELS[1])

    def test_unlisted_model_not_sent(self):
        with patch.dict(os.environ, {'SILICONFLOW_API_KEY': 'test'}), patch('app.urlopen') as call:
            self.assertEqual(app.recognize({'image': 'anything', 'model': 'unknown'})[0], 400)
            call.assert_not_called()


class FastAPITests(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app.app)

    def test_health(self):
        response = self.client.get('/health')
        self.assertEqual(response.status_code, 200)
        self.assertIn('configured', response.json())

    def test_app_token_is_required_when_configured(self):
        image = base64.b64encode(b'\xff\xd8\xfftest').decode()
        with patch.dict(os.environ, {'APP_API_TOKEN': 'private-token'}):
            response = self.client.post('/recognize', json={'image': image})
        self.assertEqual(response.status_code, 401)
        self.assertNotIn('private-token', response.text)
