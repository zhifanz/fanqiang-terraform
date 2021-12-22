SOURCE_REPO=$1
TARGET_REPO=$2

docker pull $SOURCE_REPO
docker tag $SOURCE_REPO $TARGET_REPO
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(dirname $TARGET_REPO)
docker push $TARGET_REPO
docker logout || exit 0
