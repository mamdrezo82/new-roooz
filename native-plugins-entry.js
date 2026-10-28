import { registerPlugin } from '@capacitor/core';
import { LocalNotifications } from '@capacitor/local-notifications';
window.RoozYarLocalNotifications = LocalNotifications;
window.RoozYarSaveFile = registerPlugin('RoozYarSaveFile');
