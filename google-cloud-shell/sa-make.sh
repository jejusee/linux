#!/bin/bash

# 1. 홈 디렉토리 이동 및 폴더 준비
cd ~
mkdir -p sa_keys

# 2. 프로젝트 ID 확인
PROJECT_ID=$(gcloud config get-value project)
echo "현재 프로젝트: $PROJECT_ID"

# 3. 1번부터 100번까지 순회
for i in {001..100}
do
   SA_NAME="sa-$i"
   FILE_PATH="sa_keys/${PROJECT_ID}_${SA_NAME}.json"
   SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

   # [핵심] 성공할 때까지 멈추지 않는 무한 루프 (While 문)
   while true; do
       # 1. 파일이 정상적으로 존재하는지 확인
       if [ -s "$FILE_PATH" ]; then
           echo "✅ $SA_NAME 완료 (File OK)"
           break  # 성공했으니 While 문을 탈출하고 다음 번호(For 문)로 이동
       fi

       # 2. 파일이 없으면 생성 시도
       echo "♻️ $SA_NAME 생성/복구 시도 중..."

       # 기존 계정 삭제 (꼬임 방지, 에러 무시)
       gcloud iam service-accounts delete $SA_EMAIL --quiet 2>/dev/null || true
       
       # 계정 생성 (에러 무시 - 이미 있을 수 있으므로)
       gcloud iam service-accounts create $SA_NAME --display-name "Worker $i" 2>/dev/null || true

       # 키 파일 발급 (여기가 제일 중요)
       gcloud iam service-accounts keys create "$FILE_PATH" --iam-account $SA_EMAIL || true

       # 3. 결과 확인 및 대기
       if [ -s "$FILE_PATH" ]; then
           echo "🎉 $SA_NAME 생성 성공!"
           break # 성공! 다음 번호로
       else
           echo "⚠️ $SA_NAME 생성 실패/오류 발생. 5초 뒤 다시 시도합니다..."
           sleep 5 # 구글 API가 숨 쉴 시간을 주고 다시 While문 처음으로 돌아감
       fi
   done
done

echo "🏁 100개 계정 생성 및 키 발급이 완벽하게 끝났습니다."

# 4. 폴더 안으로 이동
cd sa_keys

# 5. 파일 개수 확인 (반드시 100 이어야 함)
count=$(ls -1 *.json 2>/dev/null | wc -l)
echo "현재 생성된 키 파일 개수: $count 개"

# 6. 0바이트 파일이 있는지 재확인 (아무것도 안 나와야 정상)
find . -size 0 -print

# 7. 이메일 리스트 추출 (그룹스 추가용)
gcloud iam service-accounts list --format="value(email)" | sort > email_list.txt

# 8. 압축하기
cd ..
rm -f sa_keys.zip
zip -r sa_keys.zip sa_keys
