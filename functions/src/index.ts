import * as admin from "firebase-admin";
import { setGlobalOptions } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";

import { apiFootballKey } from "./apiFootball";
import { syncSerieA } from "./sync";

admin.initializeApp();
setGlobalOptions({ region: "europe-west1", maxInstances: 5 });

/**
 * Sincronizzazione automatica: allinea Firestore a api-football ogni ora.
 * Basta per tenere risultati/orari aggiornati senza intervento manuale.
 */
export const syncSerieAScheduled = onSchedule(
  { schedule: "every 60 minutes", secrets: [apiFootballKey], timeoutSeconds: 300, memory: "256MiB" },
  async () => {
    const result = await syncSerieA();
    console.log("Sincronizzazione Serie A completata", result);
  },
);

/**
 * Sincronizzazione manuale, richiamabile dal client (o dalla console
 * Cloud Functions) senza aspettare il prossimo giro schedulato. Riservata
 * agli admin: legge users/{uid}.role, lo stesso campo usato altrove
 * nell'app per distinguere gli utenti admin, mai scrivibile dal client
 * stesso (vedi firestore.rules).
 */
export const syncSerieANow = onCall(
  { secrets: [apiFootballKey], timeoutSeconds: 300, memory: "256MiB" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Devi essere autenticato.");
    }

    const callerDoc = await admin.firestore().collection("users").doc(request.auth.uid).get();
    if (callerDoc.data()?.role !== "admin") {
      throw new HttpsError("permission-denied", "Solo un admin può forzare la sincronizzazione.");
    }

    return syncSerieA();
  },
);
