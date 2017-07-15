FROM perl:5.24

# Carton
RUN cpanm Carton

# Perltidy
RUN cpanm Perl::Tidy;

RUN mkdir -p /mnt/moosex-dic

WORKDIR /mnt/moosex-dic
