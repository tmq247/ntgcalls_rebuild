# ===== install_prebuilt_ntgcalls.sh =====
set -euo pipefail

# --- cấu hình của bạn ---
REPO_OWNER="tmq247"
REPO_NAME="ntgcalls_rebuild"
RAW_FILE_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main/ntgcalls.so"
VENV_DIR="${HOME}/.ntg"              # đổi nếu muốn
PY_CMD="${PY_CMD:-python3.12}"       # ưu tiên python3.12; đổi sang python3 nếu máy bạn khác

echo "[1/6] Cài thư viện runtime cần thiết (an toàn)."
if command -v apt >/dev/null 2>&1; then
  sudo apt update -y
  sudo apt install -y wget ca-certificates ${PY_CMD}-venv || sudo apt install -y wget ca-certificates python3-venv
  sudo apt install -y libstdc++6 zlib1g || true
  # Nếu bạn stream có Pulse/ALSA/X11/PipeWire thì bật thêm (không bắt buộc cho import):
  # sudo apt install -y libasound2 libpulse0 libpipewire-0.3-0 libx11-6 libglib2.0-0
fi

echo "[2/6] Tạo/kích hoạt venv: ${VENV_DIR}"
mkdir -p "${VENV_DIR%/*}" || true
${PY_CMD} -m venv "${VENV_DIR}" || python3 -m venv "${VENV_DIR}"
# shellcheck disable=SC1090
source "${VENV_DIR}/bin/activate"
python -m pip -q install -U pip >/dev/null

echo "[3/6] Tải file ntgcalls.so từ GitHub → /tmp/ntgcalls.so"
wget -q -O /tmp/ntgcalls.so "${RAW_FILE_URL}"
ls -lh /tmp/ntgcalls.so

echo "[4/6] Lấy hậu tố ABI & đường dẫn site-packages"
ABI_SUFFIX="$(python - <<'PY'
import importlib.machinery as m; print(m.EXTENSION_SUFFIXES[0])
PY
)"
SITE_PACKAGES="$(python - <<'PY'
import sysconfig; print(sysconfig.get_paths()["purelib"])
PY
)"
TARGET="${SITE_PACKAGES}/ntgcalls${ABI_SUFFIX}"
echo "  - ABI_SUFFIX: ${ABI_SUFFIX}"
echo "  - SITE_PACKAGES: ${SITE_PACKAGES}"
echo "  - Sẽ cài vào: ${TARGET}"

echo "[5/6] Chép file và đặt đúng tên ABI"
install -D /tmp/ntgcalls.so "${TARGET}"
chmod 755 "${TARGET}"

echo "[6/6] Kiểm tra import"
python - <<'PY'
import ntgcalls, inspect, sys
print("✅ ntgcalls import OK")
print("  - path:", inspect.getfile(ntgcalls))
print("  - python:", sys.version.split()[0])
PY

echo "Hoàn tất. Bật venv bằng:  source '${VENV_DIR}/bin/activate'"
