import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';  // Import for Platform Channels
import 'package:webview_flutter/webview_flutter.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize WebView for Android
 // WebView.platform = SurfaceAndroidWebView();

  runApp(const MainApp());
}

// Function to get API access token
Future<String> getApiAccessToken() async {
  final response = await http.post(
    Uri.parse('https://auth.sandbox.sa.leantech.me/oauth2/token'),
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: {
      'client_id': '2fd5f0bf-a1b7-48d8-bc4a-e8bf73bdb2da',
      'client_secret': '32666435663062662d613162372d3438',
      'grant_type': 'client_credentials',
      'scope': 'api',
    },
  );

  if (response.statusCode == 200) {
    var data = json.decode(response.body);
    return data['access_token'];
  } else {
    throw Exception('Failed to get access token');
  }
}

// Function to create a customer
Future<String> createCustomer(String token) async {
  final response = await http.post(
    Uri.parse('https://sandbox.sa.leantech.me/customers/v1'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      "app_user_id": "mohammad300" // Replace with the actual user ID
    }),
  );

  if (response.statusCode == 200) {
    var data = json.decode(response.body);
    return data['customer_id'];
  } else {
    throw Exception('Failed to create customer');
  }
}

// Platform channel for invoking native Lean SDK
class NativeLeanSDK {
  static const platform = MethodChannel('lean_sdk');

  static Future<void> connectBankAccount(String customerId, String bankId, String appToken) async {
    try {
      final result = await platform.invokeMethod('connectBankAccount', {
        "customerId": customerId,
        "bankId": bankId,
        "appToken": appToken,
        "permissions": ["identity", "accounts", "balance", "transactions"],
      });
      print('Connection Successful: $result');
    } on PlatformException catch (e) {
      print('Failed to connect: ${e.message}');
    }
  }
}

// Function to create an entity after consent
Future<void> createEntity(String customerId, String token) async {
  final response = await http.post(
    Uri.parse('https://sandbox.sa.leantech.me/entities/v1'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      "customer_id": customerId,
      "bank_identifier": "LEA1_SAMAOB_SAU", // Replace with actual bank identifier
      "account_type": "PERSONAL",
      "permissions": {
        "identity": true,
        "accounts": true,
        "balance": true,
        "transactions": true,
        "identities": true,
        "scheduled_payments": true,
        "standing_orders": true,
        "direct_debits": true,
        "beneficiaries": true,
      },
    }),
  );

  if (response.statusCode == 200) {
    var data = json.decode(response.body);
    print('Entity created: $data');
  } else {
    throw Exception('Failed to create entity');
  }
}

// Function to fetch accounts
Future<void> fetchAccounts(String entityId, String token) async {
  final response = await http.get(
    Uri.parse('https://sandbox.sa.leantech.me/data/v2/accounts?entity_id=$entityId'),
    headers: {
      'lean-app-token': token,
    },
  );

  if (response.statusCode == 200) {
    var data = json.decode(response.body);
    print('Accounts: $data');
  } else {
    throw Exception('Failed to fetch accounts');
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to the Flutter App!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Get the access token
                String token = await getApiAccessToken();

                // Create a customer and retrieve the customer ID
                String customerId = await createCustomer(token);

                // Call native SDK to connect bank account (Lean SDK)
                await NativeLeanSDK.connectBankAccount(customerId, "LEA1_SAMAOB_SAU", token);

                // Create the entity after the SDK process
                await createEntity(customerId, token);
              },
              child: const Text('Connect to Bank using Lean SDK'),
            ),
          ],
        ),
      ),
    );
  }
}
