import Foundation
 
 enum PredefinedModels {
    static func getLanguageDictionary(isMultilingual: Bool, provider: ModelProvider = .local) -> [String: String] {
        if !isMultilingual {
            return ["en": "English"]
        } else {
            // For Apple Native models, return only supported languages in simple format
            if provider == .nativeApple {
                let appleSupportedCodes = ["ar", "de", "en", "es", "fr", "it", "ja", "ko", "pt", "yue", "zh"]
                return allLanguages.filter { appleSupportedCodes.contains($0.key) }
            }
            return allLanguages
        }
    }
    
    
    static var models: [any TranscriptionModel] {
        return predefinedModels + CustomModelManager.shared.customModels
    }
    
    private static let predefinedModels: [any TranscriptionModel] = [
         LocalModel(
             name: "ggml-large-v3-turbo",
             displayName: "Large v3 Turbo",
             size: "1.5 GB",
             supportedLanguages: getLanguageDictionary(isMultilingual: true, provider: .local),
             description:
             "Large model v3 Turbo, faster than v3 with similar accuracy",
             speed: 0.75,
             accuracy: 0.97,
             ramUsage: 1.8
         )
      ]
 
     static let allLanguages = [
         "auto": "Auto-detect",
         "af": "Afrikaans",
         "am": "Amharic",
         "ar": "Arabic",
         "as": "Assamese",
         "az": "Azerbaijani",
         "ba": "Bashkir",
         "be": "Belarusian",
         "bg": "Bulgarian",
         "bn": "Bengali",
         "bo": "Tibetan",
         "br": "Breton",
         "bs": "Bosnian",
         "ca": "Catalan",
         "cs": "Czech",
         "cy": "Welsh",
         "da": "Danish",
         "de": "German",
         "el": "Greek",
         "en": "English",
         "es": "Spanish",
         "et": "Estonian",
         "eu": "Basque",
         "fa": "Persian",
         "fi": "Finnish",
         "fo": "Faroese",
         "fr": "French",
         "gl": "Galician",
         "gu": "Gujarati",
         "ha": "Hausa",
         "haw": "Hawaiian",
         "he": "Hebrew",
         "hi": "Hindi",
         "hr": "Croatian",
         "ht": "Haitian Creole",
         "hu": "Hungarian",
         "hy": "Armenian",
         "id": "Indonesian",
         "is": "Icelandic",
         "it": "Italian",
         "ja": "Japanese",
         "jw": "Javanese",
         "ka": "Georgian",
         "kk": "Kazakh",
         "km": "Khmer",
         "kn": "Kannada",
         "ko": "Korean",
         "la": "Latin",
         "lb": "Luxembourgish",
         "ln": "Lingala",
         "lo": "Lao",
         "lt": "Lithuanian",
         "lv": "Latvian",
         "mg": "Malagasy",
         "mi": "Maori",
         "mk": "Macedonian",
         "ml": "Malayalam",
         "mn": "Mongolian",
         "mr": "Marathi",
         "ms": "Malay",
         "mt": "Maltese",
         "my": "Myanmar",
         "ne": "Nepali",
         "nl": "Dutch",
         "nn": "Norwegian Nynorsk",
         "no": "Norwegian",
         "oc": "Occitan",
         "pa": "Punjabi",
         "pl": "Polish",
         "ps": "Pashto",
         "pt": "Portuguese",
         "ro": "Romanian",
         "ru": "Russian",
         "sa": "Sanskrit",
         "sd": "Sindhi",
         "si": "Sinhala",
         "sk": "Slovak",
         "sl": "Slovenian",
         "sn": "Shona",
         "so": "Somali",
         "sq": "Albanian",
         "sr": "Serbian",
         "su": "Sundanese",
         "sv": "Swedish",
         "sw": "Swahili",
         "ta": "Tamil",
         "te": "Telugu",
         "tg": "Tajik",
         "th": "Thai",
         "tk": "Turkmen",
         "tl": "Tagalog",
         "tr": "Turkish",
         "tt": "Tatar",
         "uk": "Ukrainian",
         "ur": "Urdu",
         "uz": "Uzbek",
         "vi": "Vietnamese",
         "yi": "Yiddish",
         "yo": "Yoruba",
         "yue": "Cantonese",
         "zh": "Chinese",
     ]
 }