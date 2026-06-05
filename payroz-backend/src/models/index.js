const crypto = require('crypto');
const { db } = require('../config/db');

// In-memory query matcher simulating Sequelize conditions
function matchQuery(docData, where) {
  if (!where) return true;
  
  // Use Reflect.ownKeys to get both string and symbol keys
  const keys = Reflect.ownKeys(where);
  for (const key of keys) {
    const queryValue = where[key];
    const docValue = docData[key];
    const keyStr = typeof key === 'symbol' ? key.toString() : String(key);

    // Handle Op.or
    if (keyStr.includes('Symbol(or)') || keyStr === 'Op.or') {
      if (!Array.isArray(queryValue)) continue;
      let matchedAny = false;
      for (const cond of queryValue) {
        if (matchQuery(docData, cond)) {
          matchedAny = true;
          break;
        }
      }
      if (!matchedAny) return false;
      continue;
    }

    // Handle Op.and
    if (keyStr.includes('Symbol(and)') || keyStr === 'Op.and') {
      if (!Array.isArray(queryValue)) continue;
      let matchedAll = true;
      for (const cond of queryValue) {
        if (!matchQuery(docData, cond)) {
          matchedAll = false;
          break;
        }
      }
      if (!matchedAll) return false;
      continue;
    }

    // Handle nested operators
    if (queryValue && typeof queryValue === 'object' && !Array.isArray(queryValue)) {
      const subKeys = Reflect.ownKeys(queryValue);
      for (const subKey of subKeys) {
        const opVal = queryValue[subKey];
        const subKeyStr = typeof subKey === 'symbol' ? subKey.toString() : String(subKey);

        if (subKeyStr.includes('Symbol(lt)') || subKeyStr === 'Op.lt') {
          if (!(new Date(docValue) < new Date(opVal))) return false;
        } else if (subKeyStr.includes('Symbol(gt)') || subKeyStr === 'Op.gt') {
          if (!(new Date(docValue) > new Date(opVal))) return false;
        } else if (subKeyStr.includes('Symbol(lte)') || subKeyStr === 'Op.lte') {
          if (!(new Date(docValue) <= new Date(opVal))) return false;
        } else if (subKeyStr.includes('Symbol(gte)') || subKeyStr === 'Op.gte') {
          if (!(new Date(docValue) >= new Date(opVal))) return false;
        } else if (subKeyStr.includes('Symbol(in)') || subKeyStr === 'Op.in') {
          if (!Array.isArray(opVal) || !opVal.includes(docValue)) return false;
        } else if (subKeyStr.includes('Symbol(notIn)') || subKeyStr === 'Op.notIn') {
          if (Array.isArray(opVal) && opVal.includes(docValue)) return false;
        } else if (subKeyStr.includes('Symbol(ne)') || subKeyStr === 'Op.ne') {
          if (docValue === opVal) return false;
        } else {
          // Direct fallback comparison
          if (docValue !== opVal) return false;
        }
      }
    } else if (Array.isArray(queryValue)) {
      // Sequelize: key: [val1, val2] maps to IN
      if (!queryValue.includes(docValue)) return false;
    } else {
      // Simple direct match
      if (docValue !== queryValue) return false;
    }
  }
  return true;
}

// In-memory sorting function
function sortData(list, order) {
  if (!order || !order.length) return list;
  return list.sort((a, b) => {
    for (const ord of order) {
      if (!Array.isArray(ord)) continue;
      const field = ord[0];
      const direction = ord[1] ? ord[1].toUpperCase() : 'ASC';
      
      let valA = a[field];
      let valB = b[field];

      if (valA === valB) continue;
      if (valA === undefined || valA === null) return 1;
      if (valB === undefined || valB === null) return -1;

      // Handle dates comparison
      const isDateA = typeof valA === 'string' && !isNaN(Date.parse(valA)) && valA.includes('-');
      const isDateB = typeof valB === 'string' && !isNaN(Date.parse(valB)) && valB.includes('-');
      if (isDateA && isDateB) {
        valA = new Date(valA).getTime();
        valB = new Date(valB).getTime();
      }

      if (direction === 'DESC') {
        return valA > valB ? -1 : 1;
      } else {
        return valA < valB ? -1 : 1;
      }
    }
    return 0;
  });
}

// Represents a single Firestore Document instance
class ModelInstance {
  constructor(model, id, data) {
    this._model = model;
    this.id = id;
    Object.assign(this, data);
  }

  async save() {
    const data = { ...this };
    delete data._model;
    delete data.id;

    // Convert undefined to null for Firestore compatibility
    for (const key of Object.keys(data)) {
      if (data[key] === undefined) {
        data[key] = null;
      }
    }

    data.updatedAt = new Date().toISOString();
    await this._model.collectionRef.doc(this.id).set(data, { merge: true });
    return this;
  }

  async update(newData) {
    Object.assign(this, newData);
    await this.save();
    return this;
  }

  async destroy() {
    await this._model.collectionRef.doc(this.id).delete();
  }

  changed() {
    // No-op for Sequelize compatibility
  }

  toJSON() {
    const data = { id: this.id, ...this };
    delete data._model;
    return data;
  }
}

// Firestore Model Manager
class FirestoreModel {
  constructor(name, collectionName) {
    this.name = name;
    this.collectionName = collectionName;
    this.collectionRef = db.collection(collectionName);
  }

  // Get all documents from the collection
  async _getAllDocs() {
    const snapshot = await this.collectionRef.get();
    const list = [];
    snapshot.forEach((doc) => {
      list.push(new ModelInstance(this, doc.id, doc.data()));
    });
    return list;
  }

  async findByPk(id, options = {}) {
    if (!id) return null;
    const doc = await this.collectionRef.doc(id).get();
    if (!doc.exists) return null;

    const instance = new ModelInstance(this, doc.id, doc.data());

    // Handle include if requested
    if (options.include) {
      for (const inc of options.include) {
        const targetModel = inc.model;
        const as = inc.as || targetModel.collectionName;
        
        let foreignKey = '';
        if (targetModel.name === 'Transaction') foreignKey = 'userId';
        else if (targetModel.name === 'ComplaintTicket') foreignKey = 'userId';
        else if (targetModel.name === 'TicketMessage') foreignKey = 'ticketId';
        else if (targetModel.name === 'Service') foreignKey = 'categoryId';
        else if (targetModel.name === 'Refund') foreignKey = 'transactionId';
        else if (targetModel.name === 'Cashback') foreignKey = 'transactionId';
        
        if (foreignKey) {
          const related = await targetModel.findAll({
            where: { [foreignKey]: instance.id },
            order: inc.order,
            limit: inc.limit
          });
          instance[as] = related;
        }
      }
    }
    return instance;
  }

  async findOne(options = {}) {
    const list = await this.findAll(options);
    return list.length > 0 ? list[0] : null;
  }

  async findAll(options = {}) {
    let list = await this._getAllDocs();

    // Filter in-memory
    if (options.where) {
      list = list.filter((item) => matchQuery(item, options.where));
    }

    // Sort in-memory
    if (options.order) {
      list = sortData(list, options.order);
    }

    // Limit in-memory
    if (options.limit !== undefined) {
      list = list.slice(0, options.limit);
    }

    // Handle include
    if (options.include) {
      for (const instance of list) {
        for (const inc of options.include) {
          const targetModel = inc.model;
          const as = inc.as || targetModel.collectionName;
          
          let foreignKey = '';
          if (targetModel.name === 'Transaction') foreignKey = 'userId';
          else if (targetModel.name === 'ComplaintTicket') foreignKey = 'userId';
          else if (targetModel.name === 'TicketMessage') foreignKey = 'ticketId';
          else if (targetModel.name === 'Service') foreignKey = 'categoryId';
          else if (targetModel.name === 'Refund') foreignKey = 'transactionId';
          else if (targetModel.name === 'Cashback') foreignKey = 'transactionId';
          
          if (foreignKey) {
            const related = await targetModel.findAll({
              where: {
                [foreignKey]: instance.id,
                ...(inc.where || {})
              },
              order: inc.order,
              limit: inc.limit
            });
            instance[as] = related;
          }
        }
      }
    }

    return list;
  }

  async create(data) {
    const id = data.id || crypto.randomUUID();
    const cleanData = { ...data };
    delete cleanData.id;

    for (const key of Object.keys(cleanData)) {
      if (cleanData[key] === undefined) {
        cleanData[key] = null;
      }
    }

    cleanData.createdAt = cleanData.createdAt || new Date().toISOString();
    cleanData.updatedAt = cleanData.updatedAt || new Date().toISOString();

    await this.collectionRef.doc(id).set(cleanData);
    return new ModelInstance(this, id, cleanData);
  }

  async count(options = {}) {
    const list = await this.findAll(options);
    return list.length;
  }

  async sum(field, options = {}) {
    const list = await this.findAll(options);
    return list.reduce((total, item) => {
      const val = parseFloat(item[field]);
      return total + (isNaN(val) ? 0 : val);
    }, 0);
  }

  async update(data, options = {}) {
    const list = await this.findAll(options);
    for (const item of list) {
      await item.update(data);
    }
    return [list.length];
  }

  async destroy(options = {}) {
    const list = await this.findAll(options);
    for (const item of list) {
      await item.destroy();
    }
    return list.length;
  }

  // Dummy association setup to prevent Sequelize initialization crashes
  static hasMany() {}
  static belongsTo() {}
  static hasOne() {}
  hasMany() {}
  belongsTo() {}
  hasOne() {}
}

// Define and export all models mapped to Firestore Collections
const User = new FirestoreModel('User', 'users');
const Staff = new FirestoreModel('Staff', 'staff');
const ServiceCategory = new FirestoreModel('ServiceCategory', 'categories');
const Service = new FirestoreModel('Service', 'services');
const Transaction = new FirestoreModel('Transaction', 'transactions');
const Refund = new FirestoreModel('Refund', 'refunds');
const Cashback = new FirestoreModel('Cashback', 'cashbacks');
const Referral = new FirestoreModel('Referral', 'referrals');
const ComplaintTicket = new FirestoreModel('ComplaintTicket', 'tickets');
const TicketMessage = new FirestoreModel('TicketMessage', 'ticket_messages');
const Banner = new FirestoreModel('Banner', 'banners');
const Offer = new FirestoreModel('Offer', 'offers');
const Notification = new FirestoreModel('Notification', 'notifications');
const SystemLog = new FirestoreModel('SystemLog', 'logs');
const ScratchCard = new FirestoreModel('ScratchCard', 'scratch_cards');
const StaffLog = new FirestoreModel('StaffLog', 'staff_logs');
const Feedback = new FirestoreModel('Feedback', 'feedbacks');
const LoginHistory = new FirestoreModel('LoginHistory', 'login_history');
const Coupon = new FirestoreModel('Coupon', 'coupons');

module.exports = {
  User,
  Staff,
  ServiceCategory,
  Service,
  Transaction,
  Refund,
  Cashback,
  Referral,
  ComplaintTicket,
  TicketMessage,
  Banner,
  Offer,
  Notification,
  SystemLog,
  ScratchCard,
  StaffLog,
  Feedback,
  LoginHistory,
  Coupon,
};

