# install extensions from the downloaded vsix files
if [[ ! -d "${VSIX_DIR}" ]]; then
    echo "❌ VSIX 文件夹不存在: ${VSIX_DIR}"
    exit 1
fi

for vsix in "${VSIX_DIR}"/*.vsix; do
    [[ ! -f "${vsix}" ]] && continue

    echo "[$(date +%H:%M:%S)] ⬆️ 安装 ${vsix}"
    if code --install-extension "${vsix}" --force; then
        echo "    ✅ 安装成功"
        ((success++))
    else
        echo "    ❌ 安装失败"
        ((fail++))
    fi
    echo
done
