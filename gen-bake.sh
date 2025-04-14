#!/bin/bash
# ==================================================
# Desc    : 按 docker-compose.yml 生成 docker buildx bake hcl 配置
# Author  : onexian
# Date    : 2025-04-14
# Version : v1.0
# ==================================================

set -e

INPUT_FILE="docker-compose.yml"
OUTPUT_FILE="docker-bake.hcl"
# 这里改为你自己的 hub.docker.com 账号
HUB_DOCKER_REGISTRY="onexian"

echo "// 根据bake文件构建多平台容器" > "$OUTPUT_FILE"
echo 'group "default" {' >> "$OUTPUT_FILE"
echo '  targets = [' >> "$OUTPUT_FILE"

# 读取所有服务名（非注释）
services=$(yq e '.services | keys | .[]' "$INPUT_FILE")

for service in $services; do
  context=$(yq e ".services.${service}.build.context" "$INPUT_FILE")
  if [[ "$context" != "null" && -n "$context" ]]; then
    echo "    \"$service\"," >> "$OUTPUT_FILE"
  fi
done

echo '  ]' >> "$OUTPUT_FILE"
echo '}' >> "$OUTPUT_FILE"
echo >> "$OUTPUT_FILE"

# 定义镜像仓库地址
echo "variable \"REGISTRY\" { default = \"${HUB_DOCKER_REGISTRY}\" }" >> "$OUTPUT_FILE"

# 定义构建行为参数
echo 'variable "PUSH_IMAGE" { default = true }' >> "$OUTPUT_FILE"

# 定义构建 平台
echo 'variable "PLATFORMS" { default = ["linux/amd64", "linux/arm64"] }' >> "$OUTPUT_FILE"

# Container Timezone
echo 'variable "TZ" { default = "Asia/Shanghai" }' >> "$OUTPUT_FILE"
# Container package fetch url
echo 'variable "CONTAINER_PACKAGE_URL" { default = "" }' >> "$OUTPUT_FILE"
# Available apps: certbot
echo 'variable "NGINX_INSTALL_APPS" { default = "" }' >> "$OUTPUT_FILE"
# Composer url
echo 'variable "COMPOSER_URL" { default = "mirrors.aliyun.com" }' >> "$OUTPUT_FILE"
# PHP extensions
echo 'variable "PHP_EXTENSIONS" { default = "pdo_mysql,mysqli,mbstring,gd,curl,opcache,redis,zip,bcmath,swoole,pcntl" }' >> "$OUTPUT_FILE"
echo >> "$OUTPUT_FILE"

# 为每个 context 非空的服务写 target 块
for service in $services; do
  context=$(yq e ".services.${service}.build.context" "$INPUT_FILE")
  if [[ "$context" == "null" || -z "$context" ]]; then
    continue
  fi

  echo "target \"$service\" {" >> "$OUTPUT_FILE"
  echo "  context = \"$context\"" >> "$OUTPUT_FILE"
  echo "  dockerfile = \"Dockerfile\"" >> "$OUTPUT_FILE"
  echo "  platforms = PLATFORMS" >> "$OUTPUT_FILE"
  echo "  PUSH_IMAGE = PUSH_IMAGE" >> "$OUTPUT_FILE"
  # 自动检测 *_VERSION 并作为 tag 值
  version_tag=$(yq e ".services.${service}.build.args | to_entries | map(select(.key | test(\"_VERSION$\"))) | .[0].value" "$INPUT_FILE")
  if [[ "$version_tag" != "null" && -n "$version_tag" ]]; then
    echo "  tags = [\"\${REGISTRY}/$version_tag\"]" >> "$OUTPUT_FILE"
  fi

  args_exist=$(yq e ".services.${service}.build.args" "$INPUT_FILE")
  if [[ "$args_exist" != "null" ]]; then
    echo "  args = {" >> "$OUTPUT_FILE"
    yq e ".services.${service}.build.args" "$INPUT_FILE" | \
      yq e 'to_entries | .[] | "    \(.key) = \"\(.value)\""' - >> "$OUTPUT_FILE"
    echo "  }" >> "$OUTPUT_FILE"
  fi

  echo "}" >> "$OUTPUT_FILE"
  echo >> "$OUTPUT_FILE"
done

echo "生成成功"
echo "运行构建并推送远程仓库：docker buildx bake --push"
echo "查看某个配置是否正常： docker buildx bake --print php"




