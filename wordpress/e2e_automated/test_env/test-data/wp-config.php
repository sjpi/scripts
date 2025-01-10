<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the installation.
 * You don't have to use the website, you can copy this file to "wp-config.php"
 * and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * Database settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://developer.wordpress.org/advanced-administration/wordpress/wp-config/
 *
 * @package WordPress
 */

// ** Database settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'wordpress' );

/** Database username */
define( 'DB_USER', 'wpuser' );

/** Database password */
define( 'DB_PASSWORD', '' );

/** Database hostname */
define( 'DB_HOST', 'localhost' );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         'put your unique phrase here' );
define( 'SECURE_AUTH_KEY',  'put your unique phrase here' );
define( 'LOGGED_IN_KEY',    'put your unique phrase here' );
define( 'NONCE_KEY',        'put your unique phrase here' );
define( 'AUTH_SALT',        'put your unique phrase here' );
define( 'SECURE_AUTH_SALT', 'put your unique phrase here' );
define( 'LOGGED_IN_SALT',   'put your unique phrase here' );
define( 'NONCE_SALT',       'put your unique phrase here' );

/**#@-*/

/**
 * WordPress database table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 *
 * At the installation time, database tables are created with the specified prefix.
 * Changing this value after WordPress is installed will make your site think
 * it has not been installed.
 *
 * @link https://developer.wordpress.org/advanced-administration/wordpress/wp-config/#table-prefix
 */
$table_prefix = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://developer.wordpress.org/advanced-administration/debug/debug-wordpress/
 */
define( 'WP_DEBUG', false );

/* Add any custom values between this line and the "stop editing" line. */



/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
define('AUTH_KEY',         '5?[|nut/cG5h]T>a[YNQyBKMZ,U^b*sEeOnq(L&?Dq)@./es?R~GF@J:Uby5FrJ.');
define('SECURE_AUTH_KEY',  '<Md;1({FQ}ogBZQh;0%8cd{6nB%KxV;msFXqRNvH4Fkn=!8wSgt]r^i[^oR[9+kD');
define('LOGGED_IN_KEY',    'dd5;Wte8T!)}ep&N[MD;iC(hDbe*2G/t=1~2=:^(y<|no|Gqm,hxZv3slj+XHOB(');
define('NONCE_KEY',        'x:E-k3`oO9Sp H$CxUsu@)$y/+czGN|EGo*~|[)hX2PJ|337NKLR!:t3Q~5=)%Ul');
define('AUTH_SALT',        'uV91ZdKq^v_|w;p?,*J-J$Vc-@QLcc{sQO~^{6`zMR2fjUJ6wU%a#>D&BeQ8#-,#');
define('SECURE_AUTH_SALT', 'QcH-fw;uxe5m+;I_UG.=XoR,-nNL{(SVH3M}%g%z~e*rgq;&-=K+L8|73~3K#@?_');
define('LOGGED_IN_SALT',   'Pn^5a +ETO0#XOT-%)QuQGNrO4x-4yH[H@u}jjhMWJlUi + ~8;|zCu>.vL5u4eb');
define('NONCE_SALT',       'Tshm9#*J_<Z7~bbiOLia=He$8%WYH;}R =&J[_Z(={n|>Y2=+i&ld|@7hgntcZ*L');
