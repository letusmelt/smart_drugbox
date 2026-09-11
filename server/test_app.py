import base64
import io
import json
import os
import unittest
from unittest.mock import patch
from urllib.error import HTTPError
import app


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
