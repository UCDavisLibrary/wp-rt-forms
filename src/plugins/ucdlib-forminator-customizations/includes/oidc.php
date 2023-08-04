<?php

/**
 * @description This class contains customizations for authorization and authentication
 * Most auth work is handled by the openid-connect-generic plugin, but we need some customizations
 */
class UcdlibAuth {
  public function __construct(){
    $this->oidcIsActivated = in_array('openid-connect-generic/openid-connect-generic.php', apply_filters('active_plugins', get_option('active_plugins')));

    if ( $this->oidcIsActivated ) {
      add_action('after_setup_theme', [$this, 'hideAdminBar']);
      add_action( 'openid-connect-generic-update-user-using-current-claim', [$this, 'setAdvancedRole'], 10, 2 );
      add_action( 'openid-connect-generic-user-create', [$this, 'setAdvancedRole'], 10, 2 );
      add_action( 'openid-connect-generic-login-button-text', [$this, 'loginButtonText'], 10, 1);
      add_filter ( 'allow_password_reset', function (){return false;} );
      add_filter('openid-connect-generic-user-login-test', [$this, 'authorizeUser'], 10, 2);
      add_filter('openid-connect-generic-user-creation-test', [$this, 'authorizeUser'], 10, 2);
    }

    $this->allowedClientRoles = [
      'administrator',
      'editor',
      'author',
      'subscriber'
    ];

  }

  /**
   * @description Hide the floating admin bar on front-end pages for "subscribers"
   * We force authentication for all pages on this site, and most users are assigned the subscriber role.
   * Since they can't edit the site, we hide the admin bar for them
   */
  public function hideAdminBar(){
    $user = wp_get_current_user();
    if ( !$user ) return;
    $allowedRoles = array( 'editor', 'administrator', 'author' );
    if (!array_intersect( $allowedRoles, $user->roles ) && !is_admin()) {
      show_admin_bar(false);
    }
  }

  /**
   * @description Authorize a user to view site based on their keycloak roles
   * @param $authorize boolean
   * @param $user_claim array - This is either the user id endpoint response or the id token. Depending on if the OIDC_ENDPOINT_USERINFO_URL env var is set.
   */
  public function authorizeUser( $authorize, $user_claim ){
    $authorize = false;
    $allowedRealmRoles = [
      'admin-access',
      'basic-access'
    ];

    // check realm roles
    if ( isset( $user_claim['realm_access']['roles'] ) ) {
      $intersect = array_intersect( $allowedRealmRoles, $user_claim['realm_access']['roles'] );
      if ( count( $intersect ) > 0 ) {
        return true;
      }
    }

    // check client roles
    if ( !OIDC_CLIENT_ID ) return $authorize;
    if ( !isset( $user_claim['resource_access'][OIDC_CLIENT_ID]['roles'] ) ) return $authorize;
    $clientRoles = $user_claim['resource_access'][OIDC_CLIENT_ID]['roles'];
    $intersect = array_intersect( $this->allowedClientRoles, $clientRoles );
    if ( count( $intersect ) > 0 ) {
      return true;
    }
    return $authorize;
  }

  /**
   * @description Set the wordpress user role beyond default subscriber,
   * if the user has a corresponding claim in access token from identity provider.
   */
  public function setAdvancedRole($user, $userClaim){
    $tokensEncoded = get_user_meta( $user->ID, 'openid-connect-generic-last-token-response', true );
    if ( !$tokensEncoded ) return;
    try {
      $parts = explode( '.', $tokensEncoded['access_token'] );
      if ( count( $parts ) != 3 ) return;
      $accessToken = json_decode(
        base64_decode(
          str_replace(
            array( '-', '_' ),
            array( '+', '/' ),
            $parts[1]
          )
        ),
        true
      );
    } catch (\Throwable $th) {
      return;
    }
    if ( !$accessToken ) return;

    // check realm roles
    if ( isset( $accessToken['realm_access']['roles'] ) ) {
      if ( in_array('admin-access',  $accessToken['realm_access']['roles']) ){
        $user->set_role( 'administrator' );
        return;
      }
    }

    // check client roles
    if ( !OIDC_CLIENT_ID ) return;
    if ( !isset( $accessToken['resource_access'][OIDC_CLIENT_ID]['roles'] ) ) return;
    $roles = $accessToken['resource_access'][OIDC_CLIENT_ID]['roles'];
    $allowedRoles = array_intersect( $this->allowedClientRoles, $roles );
    if ( count( $allowedRoles ) > 0 ) {
      $allowedRoles = array_values( $allowedRoles );
      $user->set_role( $allowedRoles[0] );
    }
  }

  /**
   * @description Change the text on the OIDC login button.
   */
  public function loginButtonText($text){
    return 'Login with Your UC Davis Account';
  }
}
