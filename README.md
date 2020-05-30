[![Codemagic build status](https://api.codemagic.io/apps/5c9fc907581a2d000dec7fda/5c9fc907581a2d000dec7fd9/status_badge.svg)](https://codemagic.io/apps/5c9fc907581a2d000dec7fda/5c9fc907581a2d000dec7fd9/latest_build)

# Toptal Flutter Chat with Virgil E3Kit Flutter

This app is built on top of Toptal Flutter Chat App (https://github.com/nstosic/toptal-flutter-chat) and Virgil Flutter E3Kit Extended (https://github.com/lohQ/virgil-flutter-e3kit-extended). 

# Description 

This app uses double ratchet encryption to secure chat between two uses. Messages are only stored temporarily on cloud, deleted once received by another user. 

Allows to delete chatroom, but after deletion user could not initiate the creation of the chatroom. Must request for the opposite user to create it. 

# Mapping of e3kit function to app function

1. Sign in : 
       Initialize + 
       RestorePrivateKey(has account)
       OR Register(does not has account)
       OR Unregister + Register(uninstalled previously)
      
2. Create chatroom : 
       CreateRatchetChannel
       OR DeleteRatchetChannel + CreateRatchetChannel
      
3. Delete chatroom : 
       DeleteRatchetChannel

4. Retrieve chatroom : 
       GetRatchetChannel
       OR JoinRatchetChannel

# Note

 - Android only. 
 - When reinstall the app, should delete all chatrooms of that user to prevent errors. 
 
# Future Improvements

 - Handle Google/Facebook Sign In exceptions. 
 - Create ratchet channel before adding the document to Firestore. (else opposite user may attempt to join channel before it is created). 
 - Push notifications of incoming messages. 
 - Persist chatrooms locally even after deletion of chatroom in cloud. 
 - Deactivate related chatrooms upon uninstallation (cloud functions) & delete deactivated chatrooms upon re-installation. 
 - Detect uninstallation (fcm). 
 - Re-architect the project. 

# API keys

Note - if you clone this repository and try running the project, it'll fail because I've removed API keys for Facebook and Firebase. Refer to the [Facebook](https://developers.facebook.com/docs/facebook-login/) or [Firebase](https://firebase.google.com/docs/flutter/setup) official documentation for a step-by-step guide to setting up the project.
