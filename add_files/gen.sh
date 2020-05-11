#!/bin/sh

set -eux

if [ ! "${SERVER_NAME:-}" ] && [ ! "${CLIENT_NAME:-}" ]
then
    # 対象が一切未指定の場合 localhost のサーバー証明書とする
    SERVER_NAME=localhost
fi

# サーバー証明書かクライアント証明書か
crt_type=${SERVER_NAME:+server}
crt_type=${crt_type:-client}

crt_name=${SERVER_NAME:-${CLIENT_NAME:-}}
if [ ! "${crt_name:-}" ]
then
    echo "Non target SERVER_NAME or CLIENT_NAME"
    exit
fi

cadir=/pki/CA
certsdir=/pki/${crt_type}_certs/${crt_name}

mkdir -p ${certsdir}

# CA作成
create_ca() {
    mkdir -p ${cadir}
    cd ${cadir}

    ca_c=${SUBJ_CA_C:-UN}
    ca_st=${SUBJ_CA_ST:-state}
    ca_l=${SUBJ_CA_L:-city}
    ca_o=${SUBJ_CA_O:-selfcert}
    ca_ou=${SUBJ_CA_OU:-container}
    ca_cn=${SUBJ_CA_CN:-selfcert}
    ca_email=${SUBJ_CA_emailAddress:-selfcert@example.com}
    ca_subj="/C=${ca_c}/ST=${ca_st}/L=${ca_l}/O=${ca_o}/OU=${ca_ou}/CN=${ca_cn} CA/emailAddress=${ca_email}"

    mkdir -p newcerts certs crl
    touch index.txt
    echo 00 > serial
    echo 00 > crlnumber

    openssl genrsa -out ca.key 2048
    openssl req -new -key ca.key -subj "${ca_subj}" -x509 -days 730 -extensions v3_ca -out ca.crt
}
[ -d ${cadir} ] || create_ca

# CSR作成
create_csr() {
    cd ${certsdir}

    subj_c=${SUBJ_C:-UN}
    subj_st=${SUBJ_ST:-state}
    subj_l=${SUBJ_L:-city}
    subj_o=${SUBJ_O:-${crt_name} org}
    subj_ou=${SUBJ_OU:-${crt_name} unit}
    subj_cn=${SUBJ_CN:-${crt_name}}
    subj_email=${SUBJ_emailAddress:-selfcert@${crt_name}}
    subj="/C=${subj_c}/ST=${subj_st}/L=${subj_l}/O=${subj_o}/OU=${subj_ou}/CN=${subj_cn}/emailAddress=${subj_email}"

    openssl genrsa -out ${crt_name}.key 2048
    openssl req -new -key ${crt_name}.key -reqexts v3_req -subj "${subj}" -out ${crt_name}.csr
}
create_csr

# サーバー証明書として、CSRを署名
sign_server() {
    cd ${certsdir}

    echo "subjectAltName = DNS:${crt_name},DNS:*.${crt_name}" > san.txt
    openssl ca -in ${crt_name}.csr -out ${crt_name}.crt -extfile san.txt -batch

    chmod 444 *

    openssl x509 -text -in ${crt_name}.crt -noout
}

# クライアント証明書として、CSRを署名
sign_client() {
    cd ${certsdir}

    openssl ca -in ${crt_name}.csr -out ${crt_name}.crt -batch
    openssl pkcs12 -export -out ${crt_name}.pfx -inkey ${crt_name}.key -in ${crt_name}.crt \
        -certfile ${cadir}/ca.crt \
        -passout pass:${PASSPHRASE:-passphrase}

    chmod 444 *

    openssl pkcs12 -in ${crt_name}.pfx -info -noout -passin pass:${PASSPHRASE}
}

sign_${crt_type}
