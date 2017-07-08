FROM perl:5.24

# Carton
RUN cpanm Carton

RUN mkdir -p /mnt/moosex-dic

WORKDIR /mnt/moosex-dic
