# 🔐 Identifiants de Test - DUDU Pro

## 📱 Application Flutter DUDU Pro

### 🚗 **Chauffeur Voiture (Transport Passagers)**
- **Téléphone** : `221771234567`
- **Mot de passe** : `chauffeur123`
- **Profil** : Amadou Diop
- **Véhicule** : Toyota Corolla 2020 (DK-1234-AB)
- **Abonnement** : Forfait Mensuel (45,000 FCFA)

### 🏍️ **Livreur Moto (Livraisons Colis)**
- **Téléphone** : `221771234568`
- **Mot de passe** : `livreur123`
- **Profil** : Fatou Sarr
- **Véhicule** : Honda CG 125 2021 (DK-5678-CD)
- **Abonnement** : Forfait Journalier (2,000 FCFA)

---

## 🧪 Tests à Effectuer

### 1. **Test de Connexion**
- [ ] Ouvrir l'application
- [ ] Voir les identifiants de test affichés
- [ ] Tester la connexion chauffeur
- [ ] Tester la connexion livreur
- [ ] Vérifier les messages de succès/erreur

### 2. **Test Profil Chauffeur Voiture**
- [ ] Interface adaptée au transport passagers
- [ ] Options : Covoiturage, Bagages (si cargo)
- [ ] Pas d'option "Livraisons"
- [ ] Statistiques de courses
- [ ] Abonnement mensuel visible

### 3. **Test Profil Livreur Moto**
- [ ] Interface adaptée aux livraisons
- [ ] Option : Livraisons uniquement
- [ ] Pas d'options covoiturage/bagages
- [ ] Bonus hebdomadaires visibles
- [ ] Forfait journalier uniquement

### 4. **Test Système Abonnements**
- [ ] Navigation vers abonnements
- [ ] Plans différenciés selon profil
- [ ] Restrictions moto affichées
- [ ] Interface d'achat fonctionnelle

---

## 🎯 Fonctionnalités Spécifiques

### 🚗 **Chauffeurs Voiture**
- **Covoiturage** : Gestion nombre de places
- **Transport bagages** : Si véhicule cargo
- **Tous les forfaits** : Journalier, Hebdo, Mensuel, Annuel
- **Statistiques avancées** : Revenus détaillés

### 🏍️ **Livreurs Moto**
- **Livraisons uniquement** : Pas de transport passagers
- **Maximum 20 livraisons/jour** : Sécurité
- **Bonus hebdomadaires** : Performance récompensée
- **Forfait journalier uniquement** : 2,000 FCFA/jour

---

## 📊 Données de Test

### **Chauffeur Amadou Diop**
- **Courses totales** : 245
- **Note moyenne** : 4.8/5
- **Revenus totaux** : 1,250,000 FCFA
- **Courses aujourd'hui** : 12
- **Revenus aujourd'hui** : 48,000 FCFA

### **Livreur Fatou Sarr**
- **Livraisons totales** : 180
- **Note moyenne** : 4.9/5
- **Revenus totaux** : 450,000 FCFA
- **Livraisons aujourd'hui** : 8
- **Revenus aujourd'hui** : 16,000 FCFA
- **Bonus gagnés** : 15,000 FCFA

---

## 🔧 Problèmes Potentiels

### **Si l'Application ne se Lance Pas**
1. Vérifier que Flutter est installé
2. Nettoyer le cache : `flutter clean`
3. Reinstaller les dépendances : `flutter pub get`
4. Rebuilder : `flutter run -d "iPhone 16 Pro"`

### **Si la Connexion Échoue**
1. Vérifier les identifiants exacts
2. Vérifier la connexion réseau
3. Redémarrer l'application
4. Vérifier les logs de debug

### **Si l'Interface est Problématique**
1. Vérifier l'adaptation responsive
2. Tester sur différentes tailles
3. Vérifier les contraintes de layout
4. Optimiser les performances

---

## 📱 Émulateur iPhone 16 Pro

### **Spécifications**
- **Modèle** : iPhone 16 Pro
- **Taille d'écran** : 6.3 pouces
- **Résolution** : 1206 x 2616 pixels
- **iOS** : 18.2
- **Simulateur** : iOS Simulator

### **Fonctionnalités Testées**
- [ ] Géolocalisation
- [ ] Carte Google Maps
- [ ] Interface responsive
- [ ] Navigation fluide
- [ ] Gestion des erreurs

---

## 🎉 Résultats Attendus

### ✅ **Succès**
- Application se lance sans erreur
- Connexion avec identifiants de test
- Interface adaptée selon le profil
- Fonctionnalités différenciées
- Système d'abonnements opérationnel

### ⚠️ **Warnings Acceptables**
- Messages de compilation non bloquants
- Warnings de performance
- Alertes de sécurité mineures

### ❌ **Échecs Critiques**
- Crashes de l'application
- Connexion impossible
- Interface cassée
- Fonctionnalités non opérationnelles

---

*Guide de test créé le : $(date)*
*Version Flutter : 3.32.4*
*Émulateur : iPhone 16 Pro*
