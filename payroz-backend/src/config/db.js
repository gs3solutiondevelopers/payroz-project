const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

require('dotenv').config();

let db;
let isMock = false;

// Helper to check if running in a Google Cloud managed environment
const isGcpEnvironment = () => {
  return !!(
    process.env.GAE_ENV ||            // Google App Engine
    process.env.K_SERVICE ||          // Cloud Run / Functions
    process.env.GOOGLE_CLOUD_PROJECT  // GCP Project env
  );
};

const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
const hasServiceAccountFile = fs.existsSync(serviceAccountPath);
const hasEnvKey = !!process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
const hasEmulator = !!process.env.FIRESTORE_EMULATOR_HOST;
const hasGac = !!process.env.GOOGLE_APPLICATION_CREDENTIALS;

// We use real Firestore if credentials/emulator exist OR we are in a GCP environment (which has default metadata credentials)
const shouldUseRealFirestore = hasServiceAccountFile || hasEnvKey || hasEmulator || hasGac || isGcpEnvironment();

if (shouldUseRealFirestore) {
  try {
    if (admin.apps.length === 0) {
      if (hasServiceAccountFile) {
        console.log('[FIREBASE] Initializing with serviceAccountKey.json...');
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccountPath),
        });
      } else if (hasEnvKey) {
        console.log('[FIREBASE] Initializing with FIREBASE_SERVICE_ACCOUNT_KEY...');
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
        });
      } else {
        console.log('[FIREBASE] Initializing with default application credentials / emulator...');
        admin.initializeApp({
          projectId: process.env.FIREBASE_PROJECT_ID || 'payroz-b2c',
        });
      }
    }
    db = admin.firestore();
    console.log('[FIREBASE] Real Firestore database initialized successfully!');
  } catch (err) {
    console.error('[FIREBASE] Error initializing real Firestore. Falling back to local Mock database. Error:', err.message);
    isMock = true;
  }
} else {
  isMock = true;
}

if (isMock) {
  console.log('[FIREBASE] No Google Cloud credentials found. Running in offline mode using persistent firestore_mock.json.');
  
  class MockFirestore {
    constructor() {
      this.filePath = path.join(__dirname, '../../firestore_mock.json');
      this.data = {};
      this.load();
    }

    load() {
      if (fs.existsSync(this.filePath)) {
        try {
          this.data = JSON.parse(fs.readFileSync(this.filePath, 'utf8'));
        } catch (err) {
          this.data = {};
        }
      } else {
        this.data = {};
        this.save();
      }
    }

    save() {
      fs.writeFileSync(this.filePath, JSON.stringify(this.data, null, 2), 'utf8');
    }

    collection(collectionName) {
      if (!this.data[collectionName]) {
        this.data[collectionName] = {};
      }
      const self = this;

      return {
        get: async () => {
          const docsMap = self.data[collectionName] || {};
          const docsList = Object.keys(docsMap).map(id => {
            return {
              id,
              ref: {
                delete: async () => {
                  delete self.data[collectionName][id];
                  self.save();
                }
              },
              data: () => docsMap[id]
            };
          });
          return {
            empty: docsList.length === 0,
            forEach: (callback) => {
              docsList.forEach(callback);
            }
          };
        },
        doc: (id) => {
          const docId = id || crypto.randomUUID();
          return {
            id: docId,
            get: async () => {
              const exists = !!(self.data[collectionName] && self.data[collectionName][docId]);
              const docData = exists ? self.data[collectionName][docId] : null;
              return {
                exists,
                id: docId,
                data: () => docData
              };
            },
            set: async (val, options = {}) => {
              if (!self.data[collectionName]) {
                self.data[collectionName] = {};
              }
              if (options.merge && self.data[collectionName][docId]) {
                self.data[collectionName][docId] = {
                  ...self.data[collectionName][docId],
                  ...val
                };
              } else {
                self.data[collectionName][docId] = val;
              }
              self.save();
              return { id: docId };
            },
            delete: async () => {
              if (self.data[collectionName] && self.data[collectionName][docId]) {
                delete self.data[collectionName][docId];
                self.save();
              }
            }
          };
        }
      };
    }

    batch() {
      const operations = [];
      const self = this;
      return {
        delete: (docRef) => {
          operations.push({ type: 'delete', ref: docRef });
        },
        set: (docRef, data, options) => {
          operations.push({ type: 'set', ref: docRef, data, options });
        },
        commit: async () => {
          for (const op of operations) {
            if (op.type === 'delete') {
              await op.ref.delete();
            } else if (op.type === 'set') {
              await op.ref.set(op.data, op.options);
            }
          }
          self.save();
        }
      };
    }
  }

  db = new MockFirestore();
}

// Mock sequelize object to prevent seed.js and index.js from crashing when calling sync
const sequelize = {
  sync: async () => {
    console.log('[MOCK-SEQUELIZE] Database synced.');
    return true;
  }
};

module.exports = { db, admin: shouldUseRealFirestore ? admin : null, sequelize };
