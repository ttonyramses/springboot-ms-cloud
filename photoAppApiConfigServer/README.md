# API Encryption Key Generator

## Description
Ce projet contient les clés de chiffrement nécessaires pour sécuriser l'API. 

## Prérequis
- Java JDK installé sur votre machine
- Accès aux droits d'administration pour l'exécution des commandes

## Génération de la clé
Pour générer la paire de clés, exécutez la commande suivante dans votre terminal :
```bash
keytool -genkeypair -alias apiEncryptionKey -keyalg RSA -dname "CN=Tony Tafeumewe,OU=API Development,O=appsdeveloperblog.com,L=Rouen,S=ON,C=FR" -keypass azerty12 -keystore apiEncryptionKey.jks -storepass azerty12
```

### Détails de la commande
- **alias** : apiEncryptionKey (nom de l'alias de la clé)
- **keyalg** : RSA (algorithme de chiffrement)
- **keystore** : apiEncryptionKey.jks (fichier de stockage des clés)
- **storepass** : azerty12 (mot de passe du keystore)
- **keypass** : azerty12 (mot de passe de la clé)

## Informations du certificat
- **CN** (Common Name) : Tony Tafeumewe
- **OU** (Organizational Unit) : API Development
- **O** (Organization) : appsdeveloperblog.com
- **L** (Locality) : Rouen
- **S** (State) : ON
- **C** (Country) : FR

## Sécurité
⚠️ **Important** : Pour un environnement de production, il est fortement recommandé de :
- Modifier les mots de passe par défaut
- Stocker le fichier keystore dans un emplacement sécurisé
- Ne pas commiter les mots de passe dans le contrôle de version

## Maintenance
Assurez-vous de :
- Sauvegarder régulièrement votre keystore
- Renouveler les clés selon votre politique de sécurité
- Documenter toute modification apportée aux clés

## Support
Pour toute question ou assistance, veuillez contacter l'équipe de sécurité.


