#!/bin/bash

# 1. 저장할 폴더 생성
mkdir -p sa_keys
cd sa_keys

# 2. SA 100개 생성 및 키 다운로드 (반복문)
# sa-001 부터 sa-100 까지 생성됩니다.
for i in {001..100}
do
   SA_NAME="sa-$i"
   # 서비스 계정 생성
   gcloud iam service-accounts create $SA_NAME --display-name "Worker $i"
   
   # 이메일 주소 조합
   SA_EMAIL="$SA_NAME@$(gcloud config get-value project).iam.gserviceaccount.com"
   
   # 키 파일(JSON) 생성 및 저장
   gcloud iam service-accounts keys create "$SA_NAME.json" --iam-account $SA_EMAIL
   
   echo "Created $SA_NAME"
done

# 3. 이메일 리스트 추출 (나중에 그룹스에 넣을 것)
gcloud iam service-accounts list --format="value(email)" > email_list.txt

# 4. 키 파일 압축
cd ..
zip -r sa_keys.zip sa_keys
