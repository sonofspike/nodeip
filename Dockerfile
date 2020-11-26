FROM registry.access.redhat.com/ubi8/ubi-minimal
LABEL description="Helper application to select the proper pod"
RUN microdnf install -y iproute iputils && microdnf clean all
COPY nodeip.sh /
