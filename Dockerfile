
# Set the base image
FROM php:7.4-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip

# Clear system cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Install Composer
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Set document root as environment variable
ENV APACHE_DOCUMENT_ROOT /var/www/html/public

# Configure Apache document root
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Enable mod_rewrite for .htaccess files
RUN a2enmod rewrite

# Copy composer requirements
COPY composer.json composer.lock /var/www/html/

# Set working directory
WORKDIR /var/www/html

# Install dependencies
RUN composer install --prefer-dist --no-scripts --no-dev --no-autoloader && rm -rf /root/.composer

# Copying rest of the application
COPY . /var/www/html

# Finish composer
RUN composer dump-autoload --no-scripts --no-dev --optimize

# Change ownership
RUN chown -R www-data:www-data /var/www/html/storage
RUN chmod -R 775 /var/www/html/storage

# Expose port 80 and start apache service
EXPOSE 80
CMD ["apache2-foreground"]
