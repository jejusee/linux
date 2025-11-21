#!/bin/bash

# 1. 홈 디렉토리 이동 및 폴더 준비
cd ~
mkdir -p sa_keys

# 2. 프로젝트 ID 확인
PROJECT_ID=$(gcloud config get-value project)
echo "현재 프로젝트: $PROJECT_ID"

# 3. 1번부터 100번까지 생성 시작
for i in {001..100}
do
   SA_NAME="sa-$i"
   SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"
   
   # [수정됨] 파일명 앞에 프로젝트 ID를 붙여서 절대 중복되지 않게 함
   FILE_NAME="${PROJECT_ID}_${SA_NAME}.json"
   FILE_PATH="sa_keys/$FILE_NAME"

   # 무한 재시도 루프
   while true; do
       if [ -s "$FILE_PATH" ]; then
           echo "✅ $FILE_NAME 완료 (File OK)"
           break
       fi

       echo "♻️ $SA_NAME 계정 및 키 파일($FILE_NAME) 생성 시도 중..."

       # 기존 계정 정리 및 생성
       gcloud iam service-accounts delete $SA_EMAIL --quiet 2>/dev/null || true
       gcloud iam service-accounts create $SA_NAME --display-name "Worker $i" 2>/dev/null || true

       # 키 발급
       gcloud iam service-accounts keys create "$FILE_PATH" --iam-account $SA_EMAIL || true

       # 성공 확인
       if [ -s "$FILE_PATH" ]; then
           echo "🎉 성공!"
           break
       else
           echo "⚠️ 실패. 5초 후 재시도..."
           sleep 5
       fi
   done
done

# 7. 이메일 리스트 추출 (그룹스 추가용)
cd sa_keys
gcloud iam service-accounts list --format="value(email)" | sort > email_list.txt

# 4. 압축 (파일명이 길어졌으니 다시 리스트 뽑고 압축)
cd ..
rm -f sa_keys.zip
zip -r sa_keys.zip sa_keys

echo "🏁 모든 작업 완료. 다운로드 하세요."
