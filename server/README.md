# 处方识别本地开发服务

仅使用 Python 3 标准库。当前默认硅基流动 `Qwen/Qwen3-VL-32B-Instruct`。

1. 打开 `server/.env`（首次可复制 `.env.example`），填写 `SILICONFLOW_API_KEY=` 后面的值。
2. 在项目根目录运行 `python3 server/app.py`。修改 Key 后重启后端。
3. 运行 `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5175`。
4. 手机与 Mac 在同一 Wi-Fi，打开 `http://电脑局域网IP:5175`。把该网址加到 `.env` 的 `ALLOWED_ORIGINS` 中，逗号分隔且不带末尾斜杠。网页默认访问同一主机的 8787 端口。

照片选择后，点击“识别并整理”才发送至模型服务。JPEG/PNG 不超过 10 MB；HEIC 暂需转换。浏览器是否直接打开相机由浏览器决定，也可从相册导入。

原生 iOS/Android 后续测试需使用可访问的 HTTPS 后端，并通过 `--dart-define=API_BASE_URL=https://你的后端` 配置；当前局域网 HTTP 流程用于 Safari 预览。

此服务仅用于可信局域网开发，未提供用户鉴权、速率限制或持久化，不能直接发布到公网。CORS 不是鉴权。Key 只存后端；`.env` 被 Git 忽略。服务不主动记录照片或识别文本，不控制第三方模型平台的数据保留策略。

模型仅提取原文，不补全缺失剂量，字段未知时返回 null；APP 显示“待确认”，保留规格、对应原文、照片和提示供人工核对。通用结构校验不能保证药名或剂量正确，尚未做真实处方准确率评测。用药文本、每日安排与确认记录保存在本机，照片仅在内存中。网页存储按网址隔离，改变局域网 IP 后需回到原网址访问原记录。

测试：`python3 -m unittest discover -s server -p 'test_*.py'`，使用模拟响应，不消耗 API 额度。
