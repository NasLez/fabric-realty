#!/bin/bash

# 设置错误时立即退出
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 命令未找到，请确保已安装必要的依赖"
        exit 1
    fi
}

log_info "检查必要的依赖..."
check_command docker
check_command docker-compose

echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}   Fabric-Realty 一键安装脚本${NC}"
echo -e "${GREEN}================================${NC}\n"

# 镜像加速说明
echo -e "${BLUE}镜像加速说明：${NC}"
echo -e "1. 本项目依赖的 Docker 镜像默认从 Docker Hub 下载"
echo -e "2. 若下载速度较慢，可选择使用镜像加速功能"
echo -e "3. 镜像加速采用 ${YELLOW}https://github.com/togettoyou/hub-mirror${NC} 项目提供的阿里云镜像服务\n"

read -p "$(echo -e ${YELLOW}"是否使用镜像加速下载？若 Docker Hub 下载较慢可选择使用 [y/N] "${NC})" use_mirror
if [[ $use_mirror == [yY] ]]; then
    log_info "将使用镜像加速下载..."

    # 拉取并重命名镜像
    docker pull registry.cn-hangzhou.aliyuncs.com/hubmirrorbytogettoyou/togettoyou.fabric-realty.server:latest && docker tag registry.cn-hangzhou.aliyuncs.com/hubmirrorbytogettoyou/togettoyou.fabric-realty.server:latest togettoyou/fabric-realty.server:latest
    docker pull registry.cn-hangzhou.aliyuncs.com/hubmirrorbytogettoyou/hyperledger.fabric-orderer:2.5.10 && docker tag registry.cn-hangzhou.aliyuncs.com/hubmirrorbytogettoyou/hyperledger.fabric-orderer:2.5.10 hyperledger/fabric-orderer:2.5.10
    docker pull registry.cn-hangzhou.aliyuncs.com/hubmirrorbytogettoyou/hyperledger.fabric-baseos:2.5 && docker tag registry.cn-hangzhou.aliyuncs.com/hubmirrorbytogettoyou/hyperledger.fabric-baseos:2.5 hyperledger/fabric-baseos:2.5
    docker pull registry.cn-hangzhou.aliyuncs.com/hubmirrorbytogettoyou/togettoyou.fabric-realty.web:latest && docker tag registry.cn-hangzhou.aliyuncs.com/hubmirrorbytogettoyou/togettoyou.fabric-realty.web:latest togettoyou/fabric-realty.web:latest
    docker pull registry.cn-hangzhou.aliyuncs.com/hubmirrorbytogettoyou/hyperledger.fabric-tools:2.5.10 && docker tag registry.cn-hangzhou.aliyuncs.com/hubmirrorbytogettoyou/hyperledger.fabric-tools:2.5.10 hyperledger/fabric-tools:2.5.10
    docker pull registry.cn-hangzhou.aliyuncs.com/hubmirrorbytogettoyou/hyperledger.fabric-ccenv:2.5 && docker tag registry.cn-hangzhou.aliyuncs.com/hubmirrorbytogettoyou/hyperledger.fabric-ccenv:2.5 hyperledger/fabric-ccenv:2.5
    docker pull registry.cn-hangzhou.aliyuncs.com/hubmirrorbytogettoyou/hyperledger.fabric-peer:2.5.10 && docker tag registry.cn-hangzhou.aliyuncs.com/hubmirrorbytogettoyou/hyperledger.fabric-peer:2.5.10 hyperledger/fabric-peer:2.5.10
else
    log_info "跳过镜像加速，后续将直接从 Docker Hub 下载镜像..."
fi

# 部署区块链网络
log_info "开始部署区块链网络..."
cd network
if [ ! -f "./install.sh" ]; then
    log_error "network/install.sh 文件不存在！"
    exit 1
fi

log_info "执行 network/install.sh..."
./install.sh
if [ $? -ne 0 ]; then
    log_error "区块链网络部署失败！"
    exit 1
fi
log_success "区块链网络部署完成"

# 返回项目根目录
cd ..

# 启动应用服务
log_info "开始启动应用服务..."
cd application
if [ ! -f "docker-compose.yml" ]; then
    log_error "application/docker-compose.yml 文件不存在！"
    exit 1
fi

log_info "执行 docker-compose up -d..."
docker-compose up -d
if [ $? -ne 0 ]; then
    log_error "应用服务启动失败！"
    exit 1
fi
log_success "应用服务启动完成"

# 检查服务状态
log_info "检查服务状态..."
sleep 5
if [ "$(docker-compose ps -q | wc -l)" -gt 0 ]; then
    log_success "所有服务已成功启动"
else
    log_error "部分服务可能未正常启动，请检查 docker-compose logs"
    exit 1
fi

echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}   安装部署完成！   ${NC}"
echo -e "${GREEN}================================${NC}\n"
