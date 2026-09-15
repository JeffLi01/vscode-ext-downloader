# install extensions from the downloaded vsix files
if [[ ! -d "${VSIX_DIR}" ]]; then
    echo "❌ VSIX 文件夹不存在: ${VSIX_DIR}"
    exit 1
fi

total=$(find "${VSIX_DIR}" -maxdepth 1 -type f -name "*.vsix" | wc -l)
if [[ ${total} -eq 0 ]]; then
    echo "❌ VSIX 文件夹中没有找到任何 .vsix 文件: ${VSIX_DIR}"
    exit 1
fi

success=0
fail=0

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

echo "[$(date +%H:%M:%S)] 📊 安装结果: 成功 ${success} 个, 失败 ${fail} 个"
