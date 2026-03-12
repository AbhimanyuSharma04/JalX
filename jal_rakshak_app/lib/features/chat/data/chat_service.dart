
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';

final chatServiceProvider = Provider((ref) => ChatService());

class ChatService {
  Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.openRouterApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.openRouterApiKey}',
          'HTTP-Referer': 'https://jal-x.com', // Optional, for OpenRouter rankings
          'X-Title': 'JAL-X', // Optional
        },
        body: jsonEncode({
          'model': 'stepfun/step-3.5-flash:free',
          'messages': [
            {
              'role': 'system',
              'content': "You are 'JAL-X AI', a compassionate, reliable, and knowledgeable public health assistant focused on water safety and waterborne diseases. Your goal is to help users identify potential waterborne diseases based on their symptoms, provide immediate home remedies, and advise on when to see a doctor. You also provide water safety tips and prevention methods.\n\nTraits:\n- *Empathetic*: Acknowledge the user's distress (e.g., 'I'm sorry to hear you're feeling unwell').\n- *Clear & Concise*: Use simple language. Avoid overly complex medical jargon unless necessary.\n- *Safe*: Always include a disclaimer that you are an AI and not a doctor. For severe symptoms, urge them to visit a healthcare professional immediately.\n- *Local Context*: Since this app is for Indian users ('JAL-X' means Water Protector), suggest remedies relevant to India (e.g., ORS, boiled water) if applicable.\n\nStructure of Response:\n1. *Acknowledge & Empathize*: briefly validate their input.\n2. *Analyze*: Based on symptoms, suggest what it *might* be (e.g., 'These symptoms are common in Cholera or Typhoid...').\n3. *Advice*: Provide home care steps (hydration, hygiene).\n4. *Warning*: List danger signs (blood in stool, severe dehydration) that require a hospital visit.\n5. *Prevention*: quick tip on water safety.\n\nDisclaimer: Always end with 'Consult a doctor for a proper diagnosis.'",
            },
            {
              'role': 'user',
              'content': message,
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
           return data['choices'][0]['message']['content'] ?? 'No response from AI.';
        }
        return 'No response content found.';
      } else {
        print("DEBUG: OpenRouter API failed. StatusCode: ${response.statusCode}, Body: ${response.body}");
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      print("DEBUG: ChatService exception: $e");
      throw Exception('Error communicating with AI: $e');
    }
  }
}
