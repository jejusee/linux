#!/bin/bash

# 1. 홈 디렉토리로 이동 및 폴더 준비
cd ~
mkdir -p sa_keys

# 2. 프로젝트 ID 확인
PROJECT_ID=$(gcloud config get-value project)
echo "현재 프로젝트: $PROJECT_ID"

# 3. 001번부터 100번까지 전수 검사 및 복구 시작
for i in {001..100}
do
   SA_NAME="sa-$i"
   FILE_PATH="sa_keys/$SA_NAME.json"
   SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

   # [검사] 파일이 존재하고 용량이 0보다 큰가? (-s 옵션)
   if [ -s "$FILE_PATH" ]; then
       # 정상이면 건너뜀 (속도 향상)
       echo "✅ Skipping $SA_NAME (File OK)"
   else
       # 파일이 없거나 0바이트라면 복구 시작
       echo "♻️ Repairing $SA_NAME (Re-creating)..."
       
       # [삭제] 꼬여있을 수 있는 기존 계정을 클라우드에서 삭제 (에러나도 무시)
       gcloud iam service-accounts delete $SA_EMAIL --quiet || true
       
       # [생성] 계정 새로 생성
       gcloud iam service-accounts create $SA_NAME --display-name "Worker $i"

       # [키 발급] 키 파일 생성
       gcloud iam service-accounts keys create "$FILE_PATH" --iam-account $SA_EMAIL
   fi
done

echo "🎉 모든 작업이 완료되었습니다."

# 4. 폴더 안으로 이동
cd sa_keys

# 5. 파일 개수 확인 (반드시 100 이어야 함)
count=$(ls -1 *.json 2>/dev/null | wc -l)
echo "현재 생성된 키 파일 개수: $count 개"

# 6. 0바이트 파일이 있는지 재확인 (아무것도 안 나와야 정상)
find . -size 0 -print

# 7. 이메일 리스트 추출 (그룹스 추가용)
gcloud iam service-accounts list --format="value(email)" > email_list.txt

# 8. 압축하기
cd ..
rm -f sa_keys.zip
zip -r sa_keys.zip sa_keys
