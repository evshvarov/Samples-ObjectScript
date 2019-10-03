ARG IMAGE=store/intersystems/iris-community:2019.2.0.107.0
ARG IMAGE=store/intersystems/iris-community:2019.3.0.309.0
FROM $IMAGE

USER root

RUN mkdir /opt/app && chown irisowner:irisowner /opt/app

USER irisowner

WORKDIR /opt/app

COPY ./Installer.cls ./
COPY ./src ./src/

RUN iris start $ISC_PACKAGE_INSTANCENAME quietly EmergencyId=sys,sys && \
    /bin/echo -e "sys\nsys\n" \
            " Do ##class(Security.Users).UnExpireUserPasswords(\"*\")\n" \
            " Do ##class(Security.Users).AddRoles(\"admin\", \"%ALL\")\n" \
            " Do ##class(Security.System).Get(,.p)\n" \
            " // 2**4 = 16; this sets bit 4 to enable OS authentication for the admin user" \
            " Set p(\"AutheEnabled\")=\$zboolean(p(\"AutheEnabled\"),16,7)\n" \
            " Do ##class(Security.System).Modify(,.p)\n" \
            " Do \$system.OBJ.Load(\"/opt/app/Installer.cls\",\"ck\")\n" \
            " Set sc = ##class(App.Installer).setup(, 3)\n" \
            " If 'sc do \$zu(4, \$JOB, 1)\n" \
            " halt" \
    | iris session $ISC_PACKAGE_INSTANCENAME && \
    /bin/echo -e "sys\nsys\n" \
    | iris stop $ISC_PACKAGE_INSTANCENAME quietly

CMD [ "-l", "/usr/irissys/mgr/messages.log" ]
