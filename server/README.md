# 处方识别 FastAPI 服务

当前默认硅基流动 `Qwen/Qwen3-VL-32B-Instruct`。

1. 打开 `server/.env`（首次可复制 `.env.example`），填写 `SILICONFLOW_API_KEY=` 后面的值。
2. 安装依赖：`python3 -m pip install -r server/requirements.txt`。
3. 在项目根目录运行 `python3 server/app.py`。修改环境变量后重启后端。
4. 运行 `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5175`。
5. 手机与 Mac 在同一 Wi-Fi，打开 `http://电脑局域网IP:5175`。把该网址加到 `.env` 的 `ALLOWED_ORIGINS` 中，逗号分隔且不带末尾斜杠。

照片选择后，点击“识别并整理”才发送至模型服务。JPEG/PNG 不超过 10 MB；HEIC 暂需转换。浏览器是否直接打开相机由浏览器决定，也可从相册导入。

## 公网部署

可将 `server` 目录部署到支持 Docker 或 Python Web Service 的平台。服务器至少配置：

- `SILICONFLOW_API_KEY`：硅基流动密钥。
- `APP_API_TOKEN`：自行生成的长随机字符串，公网部署时不要留空。
- `ALLOWED_ORIGINS`：网页前端的 HTTPS 域名，多个域名用逗号分隔。
- `HOST=0.0.0.0`；`PORT` 通常由云平台注入。

部署后用 HTTPS 地址编译 App：

```bash
flutter build ios --release \
  --dart-define=API_BASE_URL=https://你的后端域名 \
  --dart-define=APP_API_TOKEN=与服务器相同的令牌
```

`APP_API_TOKEN` 会包含在 App 中，只适合当前原型控制滥用。正式发布给多位用户前，应增加账号登录、短期用户令牌、速率限制和用量监控。

Key 只存后端；`.env` 被 Git 忽略。服务不主动记录照片或识别文本，不控制第三方模型平台的数据保留策略。CORS 只约束浏览器，不是鉴权。

模型仅提取原文，不补全缺失剂量，字段未知时返回 null；APP 显示“待确认”，保留规格、对应原文、照片和提示供人工核对。通用结构校验不能保证药名或剂量正确，尚未做真实处方准确率评测。用药文本、每日安排与确认记录保存在本机，照片仅在内存中。网页存储按网址隔离，改变局域网 IP 后需回到原网址访问原记录。

测试依赖使用 `python3 -m pip install -r server/requirements-dev.txt` 安装。运行
`python3 -m unittest discover -s server -p 'test_*.py'`，测试使用模拟响应，不消耗 API 额度。
