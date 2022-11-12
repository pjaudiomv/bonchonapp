<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ServerName ${domain}
    DocumentRoot /var/www/${domain}
    ErrorLog $${APACHE_LOG_DIR}/error.log
    CustomLog $${APACHE_LOG_DIR}/access.log combined
    RewriteEngine on
    RewriteCond %%{SERVER_NAME} =${domain}
    RewriteRule ^ https://%%{SERVER_NAME}%%{REQUEST_URI} [END,NE,R=permanent]
    <Directory "/var/www/${domain}">
    AllowOverride All
    </Directory>
</VirtualHost>
