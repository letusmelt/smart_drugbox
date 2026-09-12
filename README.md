# 安心药箱 · smart_drugbox

Flutter 智能药箱 APP 原型：拍摄或选择处方照片，通过硅基流动
`Qwen/Qwen3-VL-32B-Instruct` 整理用药信息，再逐项核对、编辑和保存。

- 深蓝色、大圆角分组界面，内置 Noto Sans SC 中文字体。
- 支持 JPEG/PNG 照片预览、识别失败重试、原图及对应原文核对。
- 未识别清楚的字段显示“待确认”；模型输出不作为自动用药依据。
- 底部新增今日用药和用药记录：8 色药格、短按播报、按住确认、撤销。
- 用药信息、每日安排和确认记录保存在本机；原照片仅本次运行可看。
- 一日三次等普通频次预填时间，需手动确认药格、时间及疗程；特殊频次不自动生成。
- 当前不含后台/锁屏系统通知、药箱硬件联动或子女与老人跨设备同步。
- 网页本地数据按网址隔离；更换 IP、清除网站数据或更换设备不会自动迁移记录。

## 本地运行

1. `flutter pub get`
2. 首次复制 `server/.env.example` 为 `server/.env`，填入 `SILICONFLOW_API_KEY`。
3. `python3 -m pip install -r server/requirements.txt`
4. `python3 server/app.py`
5. `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5175`

手机连接同一 Wi-Fi 后访问 `http://电脑局域网IP:5175`，并在后端的
`ALLOWED_ORIGINS` 中配置该网址。IP 变化后需更新网址和配置、重启后端。

API Key 仅由 Python 后端读取，不通过 Dart 参数传入前端。
`server/.env` 和旧的 `secrets.json` 均不提交到 Git。
旧 `secrets.example.json` 不用于当前识别流程。

配置、局限与原生端说明见 [server/README.md](server/README.md)。
FastAPI 后端可部署到公网 HTTPS。配置和访问令牌说明见 `server/README.md`。

## 检查

```sh
flutter analyze
python3 -m unittest discover -s server -p 'test_*.py'
```

字体来源：Google Fonts Noto Sans SC；许可见 `assets/fonts/OFL.txt`。
