VCENTER_URL="https://vcenter_ip"
VCENTER_USER="user"
VCENTER_PASS="password"
if [[ -f _CONFIG_OVERWRITE ]]; then . _CONFIG_OVERWRITE; fi

SDK_URL="$VCENTER_URL/sdk"

echo " VCENTER_SDK: $SDK_URL"
echo "VCENTER_USER: $VCENTER_USER"
echo "VCENTER_PASS: $VCENTER_PASS"

cat <<EOF > "RetrieveServiceContent.xml"
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <soapenv:Body>
        <RetrieveServiceContent xmlns="urn:vim25">
            <_this type="ServiceInstance">ServiceInstance</_this>
        </RetrieveServiceContent>
    </soapenv:Body>
</soapenv:Envelope>
EOF

cat <<EOF > "Login.xml"
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <soapenv:Body>
        <Login xmlns="urn:vim25">
            <_this type="SessionManager">SessionManager</_this>
            <userName>${VCENTER_USER}</userName>
            <password>${VCENTER_PASS}</password>
        </Login>
    </soapenv:Body>
</soapenv:Envelope>
EOF

cat <<EOF> "Logout.xml"
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <soapenv:Body>
        <Logout xmlns="urn:vim25"><_this type="SessionManager">SessionManager</_this>
        </Logout>
    </soapenv:Body>
</soapenv:Envelope>
EOF

SOAP_HEADER="content-type: text/soap+xml; charset=utf-8"
SOAP_ACTION="SOAPAction:"
SOAP_ACTION_V50="SOAPAction:urn:vim25/5.0"

# 1. get <apiVersion>5.0</apiVersion> and Cookie
curl -s -k --dump-header headers_and_cookies -H "$SOAP_HEADER" -H "$SOAP_ACTION" --data @RetrieveServiceContent.xml  -X POST "$SDK_URL"

# 2. set SOAPAction according to apiVersion, for exmple, SOAP_ACTION_V50 = "urn:vim25/5.0"
#    set Cookie like "Cookie:vmware_soap_session="5291cbce-d46f-5c6e-4a2c-e9791bc4cffc"; Path=/; HttpOnly;"
curl -s -k --cookie headers_and_cookies -H "$SOAP_HEADER" -H "$SOAP_ACTION_V50" --data @RetrieveServiceContent.xml  -X POST "$SDK_URL"

# 3. get UserSession by login
curl -s -k --cookie headers_and_cookies -H "$SOAP_HEADER" -H "$SOAP_ACTION_V50" --data @Login.xml  -X POST "$SDK_URL"

# 4. logout
curl -s -k --cookie headers_and_cookies -H "$SOAP_HEADER" -H "$SOAP_ACTION_V50" --data @Logout.xml  -X POST "$SDK_URL"


#clean up
rm headers_and_cookies RetrieveServiceContent.xml Login.xml Logout.xml

