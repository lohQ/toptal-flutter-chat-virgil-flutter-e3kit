[![Codemagic build status](https://api.codemagic.io/apps/5c9fc907581a2d000dec7fda/5c9fc907581a2d000dec7fd9/status_badge.svg)](https://codemagic.io/apps/5c9fc907581a2d000dec7fda/5c9fc907581a2d000dec7fd9/latest_build)

# Toptal Flutter Chat with Virgil E3Kit Flutter

This app is built on top of Toptal Flutter Chat App (https://github.com/nstosic/toptal-flutter-chat) and Virgil E3kit Flutter Plugin (https://github.com/cardoso/virgil-e3kit-flutter), so to enable end-to-end encryption. 

# Note

BLoC architecture. 
Facebook sign in and Google sign in. 
E3kit default encryption. (https://developer.virgilsecurity.com/docs/e3kit/end-to-end-encryption/default/)
Support 1-to-1 messaging. 
Currently does not support group messaging. 
Currently does not support double ratchet. 
Private key backed up in Virgil cloud. Hardcoded backup password.

# TODO

 - private key backup password derived from user info, instead of hardcoded. 
 - find public key at chatListScreen instead of instantMessagingScreen
 - more robust sign in
 - platform channel codes for double ratchet.  
 - platform channel codes for group messaging. 

# Build environment

This project is developed to work with `flutter channel stable`. There is no guarantee that it will work on different flutter channels.

# API keys

Note - if you clone this repository and try running the project, it'll fail because I've removed API keys for Facebook and Firebase. Refer to the [Facebook](https://developers.facebook.com/docs/facebook-login/) or [Firebase](https://firebase.google.com/docs/flutter/setup) official documentation for a step-by-step guide to setting up the project.
