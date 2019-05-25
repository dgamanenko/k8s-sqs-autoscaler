# k8s-sqs-autoscaler
Kubernetes pod autoscaler based on queue size in AWS SQS

## Usage
Create a kubernetes deployment like this:
```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: py-k8s-autoscaler
spec:
  revisionHistoryLimit: 1
  replicas: 1
  template:
    metadata:
      labels:
        app: py-k8s-autoscaler
    spec:
      serviceAccountName: sqs-autoscaler
      containers:
      - name: py-k8s-autoscaler
        image: $(docker_repo_url)/k8s-sqs-autoscaler:1.0.2
        command:
          - ./k8s-sqs-autoscaler
          - --sqs-queue-url=https://sqs.$(AWS_REGION).amazonaws.com/$(AWS_ID)/$(SQS_QUEUE)
          - --kubernetes-deployment=$(SQS_AUTOSCALER_KUBERNETES_DEPLOYMENT)
          - --kubernetes-namespace=$(POD_NAMESPACE)
          - --poll-period=10
          - --scale-down-cool-down=30
          - --scale-up-cool-down=10
          - --scale-up-messages=20 # start scale up when sqs_message_count >= scale-up-messages count
          - --scale-down-messages=10 # start scale down when sqs_message_count <= scale-down-messages count
          - --get-messages-from-queue=1 # number of messages to delete from sqs after each scale up
          - --max-pods=30
          - --min-pods=1
        env:
          - name: POD_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: AWS_DEFAULT_REGION
            value: "us-west-2"
          - name: SQS_AUTOSCALER_KUBERNETES_DEPLOYMENT
            value: "deployment-name"
          - name: LOGGING_LEVEL
            value: "ERROR"
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "1512Mi"
            cpu: "500m"
        ports:
        - containerPort: 80

```

Kubernetes permissions example

```
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sqs-autoscaler
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: sqs-autoscaler
rules:
  - apiGroups:
    - extensions
    resources:
    - deployments
    verbs:
    - get
    - list
    - watch
    - patch
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: sqs-autoscaler
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: sqs-autoscaler
subjects:
  - kind: ServiceAccount
    name: sqs-autoscaler
    namespace: example-namespace
```