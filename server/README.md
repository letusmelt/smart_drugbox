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

### Cloudflare Workers 公网版本

免费 Workers 套餐不能原样运行 FastAPI 容器，因此项目在 `cloudflare-worker/` 中提供了接口兼容的 Worker。FastAPI 文件仍保留用于本地开发。

```bash
cd cloudflare-worker
npm install
npx wrangler secret put SILICONFLOW_API_KEY
npx wrangler secret put APP_API_TOKEN
npx wrangler deploy
```

部署后使用返回的 HTTPS 地址重新构建 App，并传入相同的 `APP_API_TOKEN`。

本项目会在根目录生成被 Git 忽略的 `cloudflare-app-config.json`，真机安装时可直接使用：

```bash
flutter run -d <你的 iPhone ID> --dart-define-from-file=cloudflare-app-config.json
```

Key 只存后端；`.env` 被 Git 忽略。服务不主动记录照片或识别文本，不控制第三方模型平台的数据保留策略。CORS 只约束浏览器，不是鉴权。

模型仅提取原文，不补全缺失剂量，字段未知时返回 null；APP 显示“待确认”，保留规格、对应原文、照片和提示供人工核对。通用结构校验不能保证药名或剂量正确，尚未做真实处方准确率评测。用药文本、每日安排与确认记录保存在本机，照片仅在内存中。网页存储按网址隔离，改变局域网 IP 后需回到原网址访问原记录。

测试依赖使用 `python3 -m pip install -r server/requirements-dev.txt` 安装。运行
`python3 -m unittest discover -s server -p 'test_*.py'`，测试使用模拟响应，不消耗 API 额度。

## 阿里云部署

生产服务器使用 `deploy/smart-drugbox.service` 通过 systemd 运行 FastAPI，并由 `deploy/nginx.conf` 反向代理。Certbot 为 `api.letusmelt.xyz` 申请和续期 HTTPS 证书，FastAPI 只监听本机地址。服务器需放行 TCP 80/443，并让域名的 A 记录指向服务器公网 IP。

```bash
systemctl status smart-drugbox
curl https://api.letusmelt.xyz/health
```

项目根目录的 `aliyun-app-config.json` 被 Git 忽略，保存阿里云 API 地址和本机原型使用的 App Token。真机运行：

```bash
flutter run --release -d <你的 iPhone ID> --dart-define-from-file=aliyun-app-config.json
```

App 会优先使用 `API_BASE_URL`。若公网连接失败或超时，会自动尝试 `LOCAL_API_BASE_URL`；真机默认备用地址为 `http://yuedeMac-mini.local:8787`。备案期间测试前，在 Mac 项目根目录运行：

```bash
server/.venv/bin/python server/app.py
```

如 Mac 的局域网主机名不同，可在本机专用的 Dart define JSON 中加入：

```json
"LOCAL_API_BASE_URL": "http://你的Mac主机名.local:8787"
```
