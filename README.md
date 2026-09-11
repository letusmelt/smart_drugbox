# 安心药箱 · smart_drugbox

Flutter 智能药箱 APP 原型：拍摄或选择处方照片，通过硅基流动
`Qwen/Qwen3-VL-32B-Instruct` 整理用药信息，再逐项核对、编辑和保存。

- 深蓝色、大圆角分组界面，内置 Noto Sans SC 中文字体。
- 支持 JPEG/PNG 照片预览、识别失败重试、原图及对应原文核对。
- 未识别清楚的字段显示“待确认”；模型输出不作为自动用药依据。
- 当前处方仅在本次运行内保存，刷新或退出会丢失。

## 本地运行

1. `flutter pub get`
2. 首次复制 `server/.env.example` 为 `server/.env`，填入 `SILICONFLOW_API_KEY`。
3. `python3 server/app.py`
4. `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5175`

手机连接同一 Wi-Fi 后访问 `http://电脑局域网IP:5175`，并在后端的
`ALLOWED_ORIGINS` 中配置该网址。IP 变化后需更新网址和配置、重启后端。

API Key 仅由 Python 后端读取，不通过 Dart 参数传入前端。
`server/.env` 和旧的 `secrets.json` 均不提交到 Git。
旧 `secrets.example.json` 不用于当前识别流程。

配置、局限与原生端说明见 [server/README.md](server/README.md)。
此后端仅供可信局域网开发，发布前需要鉴权、限流和 HTTPS。

## 检查

```sh
flutter analyze
python3 -m unittest discover -s server -p 'test_*.py'
```

字体来源：Google Fonts Noto Sans SC；许可见 `assets/fonts/OFL.txt`。
