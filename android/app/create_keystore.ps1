Set-Content -Path upload-keystore.jks -Value "garbage"
Remove-Item -Path upload-keystore.jks -Force
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool" -genkey -v -keystore upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=, OU=, O=, L=, S=, C=" -storepass password -keypass password