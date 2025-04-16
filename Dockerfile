# Java 17 경량 이미지 사용
FROM eclipse-temurin:17-jdk-alpine

# 작업 디렉토리 생성
WORKDIR /app

# JAR 파일 복사
COPY ./app/build/libs/myproject-backend-board.jar app.jar

# 환경변수 기본값 설정 (원하면 오버라이드 가능)
ENV SPRING_PROFILES_ACTIVE=prod

# 실행 명령 (환경변수 사용)
ENTRYPOINT ["sh", "-c", "java -jar app.jar --spring.profiles.active=$SPRING_PROFILES_ACTIVE"]
