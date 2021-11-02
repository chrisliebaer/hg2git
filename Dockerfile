FROM alpine

COPY --chown=root:root entrypoint.sh /bin/

RUN apk --no-cache add py3-pip git mercurial dcron && \
	pip install --no-cache-dir git-remote-hg && \
	adduser -D git && \
	mkdir -p /repo && \
	chmod 755 /bin/entrypoint.sh

VOLUME /repo
WORKDIR /repo



ENTRYPOINT ["/bin/entrypoint.sh"]