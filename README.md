# myproject-backend-board

## 설정

### 스프링부트 설정 파일을 개발과 운영으로 분리

- application.properties 파일 분리
  - application-dev.properties (개발)
  - application-prod.properties (운영)
- 실행 방법
  - 환경변수를 통해 설정
    - 예) $ export SPRING_PROFILES_ACTIVE=dev
    - 예) $ gradle bootRun
    - 예) $ java -jar myapp.jar
  - JVM 아규먼트: `-Dspring.profiles.active=dev`
    - 예) $ java -Dspring.profiles.active=prod -jar myapp.jar
  - 프로그램 아규먼트: `--spring.profiles.active=dev`
    - 예) $ java -jar myapp.jar --spring.profiles.active=prod
    - 예) $ gradle bootRun --args='--spring.profiles.active=dev'
  - IntelliJ : 환경변수를 통해 설정한다.
    - bootRun -> 구성 -> 편집: spring.profiles.active=dev

### 서버 포트 번호 설정

- 실행 방법
  - 환경변수를 통해 설정할 수 있다.
    - 예) `$ export $SERVER_PORT=9010`
    - 예) `$ gradle bootRun`
    - 예) `$ java -jar myapp.jar`
  - JVM 아규먼트: `-Dserver.port=9010`
    - 예) `$ java -Dserver.port=9010 -jar myapp.jar`
  - 프로그램 아규먼트: `--server.port=9010`
    - 예) `$ java -jar myapp.jar --server.port=9010`
    - 예) `$ gradle bootRun --args='--server.port=9010`

### .env 파일에 환경 변수 설정하기

`.env` 파일에 환경 변수를 등록한다.

```properties
NCP_ENDPOINT=https://k...
NCP_REGIONNAME=kr-s...
NCP_ACCESSKEY=8...
NCP_SECRETKEY=ma...
NCP_BUCKETNAME=b...

# JDBC
JDBC_URL=jdbc:mysql://db-...
JDBC_USERNAME=st...
JDBC_PASSWORD=b...
JDBC_DRIVER=co...
```

## 빌드 및 실행 테스트

### Gradle 로 실행

```bash
./gradlew bootJar
```

### Java 로 직접 실행

```bash
export $(grep -v '^#' .env | xargs) # .env 파일에 등록된 환경변수를 OS에 등록하기
java -jar ./app/build/libs/myproject-backend-board.jar --spring.profiles.active=dev
```

## Docker Image 파일 생성

### `Dockerfile`

```
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
```

### 도커 이미지 만들기

```bash
docker build -t myproject-backend-board .
```

## 도커 컨테이너 실행하기

### Foreground 실행

- 컨테이너 로그와 출력을 즉시 터미널에서 확인 가능
- Ctrl + C 누르면 컨테이너가 종료됨
- 디버깅할 때 유용해 (예: 로그 확인, 에러 추적 등)

```bash
docker run --env-file .env -p 8020:8020 --name board-server myproject-backend-board
```

### Background 실행

- 터미널은 즉시 반환됨
- 컨테이너는 계속 실행됨
- 서비스처럼 계속 띄워두고 싶을 때 유용

```bash
docker run -d --env-file .env -p 8020:8020 --name board-server myproject-backend-board
```

### 실행 상태 확인 - 로그 보기

- 백그라운드로 실행했을 경우, 로그 보기

```bash
docker logs board-server
```

- 최근 100줄만 먼저 보고, 이후부터는 실시간으로 이어서 출력하기

```bash
docker logs -f --tail 100 board-server
```

## NCP - Container Registry 사용하기

### 로그인 하기

```bash
$ sudo docker login k8s-edu-camp71.kr.ncr.ntruss.com
Username: Access Key ID
Password: Secret Key
```

### 이미지에 태깅하기

```bash
$ sudo docker tag local-image:tagname new-repo:tagname
$ sudo docker tag myproject-backend-board k8s-edu-camp71.kr.ncr.ntruss.com/myproject-backend-board
```

#### 저장소에 이미지 올리기

```bash
$ sudo docker push k8s-edu-camp71.kr.ncr.ntruss.com/<TARGET_IMAGE[:TAG]>
$ sudo docker push k8s-edu-camp71.kr.ncr.ntruss.com/myproject-backend-board
```

## NCP - Ncloud Kubernetes Service 사용하기

### 쿠버네티스가 관리할 리소스 정의: 매니페스트 파일(Kubernetes manifest file) 작성

#### secret 타입 리소스 정의 : `board-server-secret.yml`

민감한 정보(Secrets; 예를들면 비밀번호, API 키, 인증 토큰 등)를
쿠버네티스 클러스터에 안전하게 저장하고 사용할 수 있도록 해주는 리소스 타입

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: board-server-secret
type: Opaque
stringData:
  NCP_ENDPOINT: https://kr.object.ncloudstorage.com
  NCP_REGIONNAME: kr-standard
  NCP_ACCESSKEY: ncp_iam_BPASKR9DyqAS18JKNMqE
  NCP_SECRETKEY: ncp_iam_BPKSKRRKsBWmq7dRFrOgOdZxYKeVjhteZj
  NCP_BUCKETNAME: bitcamp-camp71
  JDBC_URL: jdbc:mysql://db-33q0r7-kr.vpc-pub-cdb.ntruss.com:3306/studentdb
  JDBC_USERNAME: student
  JDBC_PASSWORD: bitcamp123!@#
  JDBC_DRIVER: com.mysql.cj.jdbc.Driver
```

#### deployment + service 타입 리소스 정의 : `board-server-deployment.yml`

- kind: Deployment
  - 애플리케이션의 "실행 상태(pod)"를 정의하고 관리하는 리소스
  - 원하는 개수의 Pod 복제본(replica)을 유지
  - 애플리케이션의 롤링 업데이트 및 롤백 지원
  - Pod가 죽으면 자동으로 재생성
- kind: Service
  - Pod 집합에 접근할 수 있는 네트워크 인터페이스를 제공하는 리소스
  - Pod의 IP가 바뀌어도 고정된 접근 지점(ClusterIP, LoadBalancer 등)을 제공
  - 내부에서 접근하거나 외부로 노출하거나 가능
  - Deployment로 생성된 Pod들을 라벨로 선택해서 연결해줌

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: board-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: board-server
  template:
    metadata:
      labels:
        app: board-server
    spec:
      imagePullSecrets:
        - name: regcred
      containers:
        - name: board-server
          image: lo20hyy7.kr.private-ncr.ntruss.com/myproject-backend-board
          ports:
            - containerPort: 8080
          envFrom:
            - secretRef:
                name: board-server-secret
---
apiVersion: v1
kind: Service
metadata:
  name: board-server-service
spec:
  selector:
    app: board-server
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
      nodePort: 30120
  type: NodePort
```

도커 이미지를 지정할 때 Private Endpoint 를 사용하면, 내부 통신으로 다뤄진다.

### 리소스 생성

#### Secret 리소스 생성

```bash
kubectl2 apply -f board-server-secret.yml
```

#### Deployment + Service 리소스 생성

```bash
kubectl2 apply -f board-server-deployment.yml
```

#### 생성된 리소스 확인

```bash
kubectl2 get secrets
kubectl2 get deployments
kubectl2 get svc
```
