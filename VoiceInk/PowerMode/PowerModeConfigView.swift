import SwiftUI

struct ConfigurationView: View {
    let mode: ConfigurationMode
    let powerModeManager: PowerModeManager
    @EnvironmentObject var enhancementService: AIEnhancementService
    @EnvironmentObject var aiService: AIService
    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var isNameFieldFocused: Bool
    
    // State for configuration
    @State private var configName: String = "New Power Mode"
    @State private var selectedEmoji: String = "💼"
    @State private var isShowingEmojiPicker = false
    @State private var isShowingAppPicker = false
    @State private var isAIEnhancementEnabled: Bool
    @State private var selectedPromptId: UUID?
    @State private var selectedTranscriptionModelName: String?
    @State private var selectedLanguage: String?
    @State private var installedApps: [(url: URL, name: String, bundleId: String, icon: NSImage)] = []
    @State private var searchText = ""
    
    // Validation state
    @State private var validationErrors: [PowerModeValidationError] = []
    @State private var showValidationAlert = false
    
    // New state for AI provider and model
    @State private var selectedAIProvider: String?
    @State private var selectedAIModel: String?
    
    // App and Website configurations
    @State private var selectedAppConfigs: [AppConfig] = []
    @State private var websiteConfigs: [URLConfig] = []
    @State private var newWebsiteURL: String = ""
    
    // New state for screen capture toggle
    @State private var useScreenCapture = false
    @State private var isAutoSendEnabled = false
    @State private var isDefault = false
    
    // State for prompt editing (similar to EnhancementSettingsView)
    @State private var isEditingPrompt = false
    @State private var selectedPromptForEdit: CustomPrompt?
    
    // Whisper state for model selection
    @EnvironmentObject private var whisperState: WhisperState
    
    // Computed property to check if current config is the default
    private var isCurrentConfigDefault: Bool {
        if case .edit(let config) = mode {
            return config.isDefault
        }
        return false
    }
    
    private var filteredApps: [(url: URL, name: String, bundleId: String, icon: NSImage)] {
        if searchText.isEmpty {
            return installedApps
        }
        return installedApps.filter { app in
            app.name.localizedCaseInsensitiveContains(searchText) ||
            app.bundleId.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // Simplified computed property for effective model name
    private var effectiveModelName: String? {
        if let model = selectedTranscriptionModelName {
            return model
        }
        return whisperState.currentTranscriptionModel?.name
    }
    
    init(mode: ConfigurationMode, powerModeManager: PowerModeManager) {
        self.mode = mode
        self.powerModeManager = powerModeManager
        
        // Always fetch the most current configuration data
        switch mode {
        case .add:
            _isAIEnhancementEnabled = State(initialValue: true)
            _selectedPromptId = State(initialValue: nil)
            _selectedTranscriptionModelName = State(initialValue: nil)
            _selectedLanguage = State(initialValue: nil)
            _configName = State(initialValue: "")
            _selectedEmoji = State(initialValue: "✏️")
            _useScreenCapture = State(initialValue: false)
            _isAutoSendEnabled = State(initialValue: false)
            _isDefault = State(initialValue: false)
            // Default to current global AI provider/model for new configurations - use UserDefaults only
            _selectedAIProvider = State(initialValue: UserDefaults.standard.string(forKey: "selectedAIProvider"))
            _selectedAIModel = State(initialValue: nil) // Initialize to nil and set it after view appears
        case .edit(let config):
            // Get the latest version of this config from PowerModeManager
            let latestConfig = powerModeManager.getConfiguration(with: config.id) ?? config
            _isAIEnhancementEnabled = State(initialValue: latestConfig.isAIEnhancementEnabled)
            _selectedPromptId = State(initialValue: latestConfig.selectedPrompt.flatMap { UUID(uuidString: $0) })
            _selectedTranscriptionModelName = State(initialValue: latestConfig.selectedTranscriptionModelName)
            _selectedLanguage = State(initialValue: latestConfig.selectedLanguage)
            _configName = State(initialValue: latestConfig.name)
            _selectedEmoji = State(initialValue: latestConfig.emoji)
            _selectedAppConfigs = State(initialValue: latestConfig.appConfigs ?? [])
            _websiteConfigs = State(initialValue: latestConfig.urlConfigs ?? [])
            // _useScreenCapture = State(initialValue: latestConfig.useScreenCapture)
            _isAutoSendEnabled = State(initialValue: latestConfig.isAutoSendEnabled)
            _isDefault = State(initialValue: latestConfig.isDefault)
            _selectedAIProvider = State(initialValue: latestConfig.selectedAIProvider)
            _selectedAIModel = State(initialValue: latestConfig.selectedAIModel)
        }
    }
    
    private var mainInputSectionView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Button(action: {
                    isShowingEmojiPicker.toggle()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 48, height: 48)
                        
                        Text(selectedEmoji)
                            .font(.system(size: 24))
                    }
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isShowingEmojiPicker, arrowEdge: .bottom) {
                    EmojiPickerView(
                        selectedEmoji: $selectedEmoji,
                        isPresented: $isShowingEmojiPicker
                    )
                }
                
                TextField("Name your power mode", text: $configName)
                    .font(.system(size: 18, weight: .bold))
                    .textFieldStyle(.plain)
                    .foregroundColor(.primary)
                    .tint(.accentColor)
                    .focused($isNameFieldFocused)
            }
            
            // Default Power Mode Toggle
            if !powerModeManager.hasDefaultConfiguration() || isCurrentConfigDefault {
                HStack {
                    Toggle("Set as default power mode", isOn: $isDefault)
                        .font(.system(size: 14))
                    
                    InfoTip(
                        title: "Default Power Mode",
                        message: "Default power mode is used when no specific app or website matches are found"
                    )
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(CardBackground(isSelected: false))
        .padding(.horizontal)
        .onAppear {
            // Add a small delay to ensure the view is fully loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isNameFieldFocused = true
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            Divider()
            scrollContentView
        }
        .sheet(isPresented: $isShowingAppPicker) {
            AppPickerSheet(
                installedApps: filteredApps,
                selectedAppConfigs: $selectedAppConfigs,
                searchText: $searchText,
                onDismiss: { isShowingAppPicker = false }
            )
        }
        .sheet(isPresented: $isEditingPrompt) {
            PromptEditorView(mode: .add)
        }
        .sheet(item: $selectedPromptForEdit) { prompt in
            PromptEditorView(mode: .edit(prompt))
        }
        .powerModeValidationAlert(errors: validationErrors, isPresented: $showValidationAlert)
        .navigationTitle("")
        .toolbar(.hidden)
        .onAppear {
            setupOnAppear()
        }
    }
    
    private var headerView: some View {
        HStack {
            Text(mode.title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer()
            
            if case .edit(let config) = mode {
                Button("Delete") {
                    powerModeManager.removeConfiguration(with: config.id)
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.red)
                .padding(.trailing, 8)
            }
            
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal)
        .padding(.top)
        .padding(.bottom, 10)
    }
    
    private var scrollContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                mainInputSectionView
                triggerSectionView
                transcriptionSectionView
                aiEnhancementSectionView
                advancedSectionView
                saveButtonView
            }
            .padding(.vertical)
        }
    }
    
    private var triggerSectionView: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "When to Trigger")
            applicationsSectionView
            Divider()
            websitesSectionView
        }
        .padding()
        .background(CardBackground(isSelected: false))
        .padding(.horizontal)
    }
    
    private var applicationsSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Applications")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    loadInstalledApps()
                    isShowingAppPicker = true
                }) {
                    Label("Add App", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
            }
            
            if selectedAppConfigs.isEmpty {
                HStack {
                    Spacer()
                    Text("No applications added")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    Spacer()
                }
                .padding()
                .background(CardBackground(isSelected: false))
            } else {
                appsGridView
            }
        }
    }
    
    private var appsGridView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50, maximum: 55), spacing: 10)], spacing: 10) {
            ForEach(selectedAppConfigs) { appConfig in
                appIconView(for: appConfig)
            }
        }
    }
    
    private func appIconView(for appConfig: AppConfig) -> some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appConfig.bundleIdentifier) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: appURL.path))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "app.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button(action: {
                    selectedAppConfigs.removeAll(where: { $0.id == appConfig.id })
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.black.opacity(0.6)))
                }
                .buttonStyle(.plain)
                .offset(x: 6, y: -6)
            }
        }
        .frame(width: 50, height: 50)
        .background(CardBackground(isSelected: false, cornerRadius: 10))
    }
    
    private var websitesSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Websites")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                TextField("Enter website URL (e.g., google.com)", text: $newWebsiteURL)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        addWebsite()
                    }
                
                Button(action: addWebsite) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
                .disabled(newWebsiteURL.isEmpty)
            }
            
            if websiteConfigs.isEmpty {
                HStack {
                    Spacer()
                    Text("No websites added")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    Spacer()
                }
                .padding()
                .background(CardBackground(isSelected: false))
            } else {
                websitesGridView
            }
        }
    }
    
    private var websitesGridView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 160), spacing: 10)], spacing: 10) {
            ForEach(websiteConfigs) { urlConfig in
                websiteTagView(for: urlConfig)
            }
        }
        .padding(8)
    }
    
    private func websiteTagView(for urlConfig: URLConfig) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "globe")
                .font(.system(size: 11))
                .foregroundColor(.accentColor)
            
            Text(urlConfig.url)
                .font(.system(size: 11))
                .lineLimit(1)
            
            Spacer(minLength: 0)
            
            Button(action: {
                websiteConfigs.removeAll(where: { $0.id == urlConfig.id })
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(height: 28)
        .background(CardBackground(isSelected: false, cornerRadius: 10))
    }
    
    private var transcriptionSectionView: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Transcription")
            
            if whisperState.usableModels.isEmpty {
                Text("No transcription models available. Please connect to a cloud service or download a local model in the AI Models tab.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(CardBackground(isSelected: false))
            } else {
                transcriptionModelPicker
                transcriptionLanguagePicker
            }
        }
        .padding()
        .background(CardBackground(isSelected: false))
        .padding(.horizontal)
    }
    
    private var transcriptionModelPicker: some View {
        let modelBinding = Binding<String?>(
            get: { selectedTranscriptionModelName ?? whisperState.usableModels.first?.name },
            set: { selectedTranscriptionModelName = $0 }
        )
        
        return HStack {
            Text("Model")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Picker("", selection: modelBinding) {
                ForEach(whisperState.usableModels, id: \.name) { model in
                    Text(model.displayName).tag(model.name as String?)
                }
            }
            .labelsHidden()
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var transcriptionLanguagePicker: some View {
        if let selectedModel = effectiveModelName,
           let modelInfo = whisperState.allAvailableModels.first(where: { $0.name == selectedModel }),
           modelInfo.isMultilingualModel {
            
            let languageBinding = Binding<String?>(
                get: { selectedLanguage ?? UserDefaults.standard.string(forKey: "SelectedLanguage") ?? "auto" },
                set: { selectedLanguage = $0 }
            )
            
            HStack {
                Text("Language")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("", selection: languageBinding) {
                    ForEach(modelInfo.supportedLanguages.sorted(by: { 
                        if $0.key == "auto" { return true }
                        if $1.key == "auto" { return false }
                        return $0.value < $1.value
                    }), id: \.key) { key, value in
                        Text(value).tag(key as String?)
                    }
                }
                .labelsHidden()
                
                Spacer()
            }
        } else if let selectedModel = effectiveModelName,
                  let modelInfo = whisperState.allAvailableModels.first(where: { $0.name == selectedModel }),
                  !modelInfo.isMultilingualModel {
            
            EmptyView()
                .onAppear {
                    if selectedLanguage == nil {
                        selectedLanguage = "en"
                    }
                }
        }
    }
    
    private var aiEnhancementSectionView: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "AI Enhancement")
            
            Toggle("Enable AI Enhancement", isOn: $isAIEnhancementEnabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: isAIEnhancementEnabled) { oldValue, newValue in
                    if newValue {
                        if selectedAIProvider == nil {
                            selectedAIProvider = aiService.selectedProvider.rawValue
                        }
                        if selectedAIModel == nil {
                            selectedAIModel = aiService.currentModel
                        }
                    }
                }
            
            if isAIEnhancementEnabled {
                Divider()
                aiProviderSection
                aiModelSection
                promptSelectionSection
                Divider()
                contextAwarenessToggle
            }
        }
        .padding()
        .background(CardBackground(isSelected: false))
        .padding(.horizontal)
    }
    
    private var aiProviderSection: some View {
        let providerBinding = Binding<AIProvider>(
            get: {
                if let providerName = selectedAIProvider,
                   let provider = AIProvider(rawValue: providerName) {
                    return provider
                }
                return aiService.selectedProvider
            },
            set: { newValue in
                selectedAIProvider = newValue.rawValue
                aiService.selectedProvider = newValue
                selectedAIModel = nil
            }
        )
        
        return HStack {
            Text("AI Provider")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if aiService.connectedProviders.isEmpty {
                Text("No providers connected")
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Picker("", selection: providerBinding) {
                    ForEach(aiService.connectedProviders, id: \.self) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .labelsHidden()
                .onChange(of: selectedAIProvider) { oldValue, newValue in
                    if let provider = newValue.flatMap({ AIProvider(rawValue: $0) }) {
                        selectedAIModel = provider.defaultModel
                    }
                }
                
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var aiModelSection: some View {
        let providerName = selectedAIProvider ?? aiService.selectedProvider.rawValue
        if let provider = AIProvider(rawValue: providerName) {
            
            HStack {
                Text("AI Model")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if aiService.availableModels.isEmpty {
                    Text("No models available")
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    aiModelPicker(for: provider)
                }
            }
        }
    }
    
    private func aiModelPicker(for provider: AIProvider) -> some View {
        let modelBinding = Binding<String>(
            get: {
                if let model = selectedAIModel, !model.isEmpty {
                    return model
                }
                return aiService.currentModel
            },
            set: { newModelValue in
                selectedAIModel = newModelValue
                aiService.selectModel(newModelValue)
            }
        )
        
        let models = aiService.availableModels
        
        return HStack {
            Picker("", selection: modelBinding) {
                ForEach(models, id: \.self) { model in
                    Text(model).tag(model)
                }
            }
            .labelsHidden()
            
            Spacer()
        }
    }
    
    private var promptSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enhancement Prompt")
                .font(.headline)
                .foregroundColor(.primary)
            
            PromptSelectionGrid(
                prompts: enhancementService.allPrompts,
                selectedPromptId: selectedPromptId,
                onPromptSelected: { prompt in
                    selectedPromptId = prompt.id
                },
                onEditPrompt: { prompt in
                    selectedPromptForEdit = prompt
                },
                onDeletePrompt: { prompt in
                    enhancementService.deletePrompt(prompt)
                },
                onAddNewPrompt: {
                    isEditingPrompt = true
                }
            )
        }
    }
    
    private var contextAwarenessToggle: some View {
        Toggle("Context Awareness", isOn: $useScreenCapture)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var advancedSectionView: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Advanced")
            
            HStack {
                Toggle("Auto Send", isOn: $isAutoSendEnabled)
                
                InfoTip(
                    title: "Auto Send",
                    message: "Automatically presses the Return/Enter key after pasting text. This is useful for chat applications or forms where its not necessary to to make changes to the transcribed text"
                )
                
                Spacer()
            }
        }
        .padding()
        .background(CardBackground(isSelected: false))
        .padding(.horizontal)
    }
    
    private var saveButtonView: some View {
        VoiceInkButton(
            title: mode.isAdding ? "Add New Power Mode" : "Save Changes",
            action: saveConfiguration,
            isDisabled: !canSave
        )
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
    
    private func setupOnAppear() {
        if case .add = mode {
            if selectedAIProvider == nil {
                selectedAIProvider = aiService.selectedProvider.rawValue
            }
            if selectedAIModel == nil || selectedAIModel?.isEmpty == true {
                selectedAIModel = aiService.currentModel
            }
        }
        
        if isAIEnhancementEnabled && selectedPromptId == nil {
            selectedPromptId = enhancementService.allPrompts.first?.id
        }
    }
    
    private var canSave: Bool {
        return !configName.isEmpty
    }
    
    private func addWebsite() {
        guard !newWebsiteURL.isEmpty else { return }
        
        let cleanedURL = powerModeManager.cleanURL(newWebsiteURL)
        let urlConfig = URLConfig(url: cleanedURL)
        websiteConfigs.append(urlConfig)
        newWebsiteURL = ""
    }
    
    private func toggleAppSelection(_ app: (url: URL, name: String, bundleId: String, icon: NSImage)) {
        if let index = selectedAppConfigs.firstIndex(where: { $0.bundleIdentifier == app.bundleId }) {
            selectedAppConfigs.remove(at: index)
        } else {
            let appConfig = AppConfig(bundleIdentifier: app.bundleId, appName: app.name)
            selectedAppConfigs.append(appConfig)
        }
    }
    
    private func getConfigForForm() -> PowerModeConfig {
        switch mode {
        case .add:
                return PowerModeConfig(
                name: configName,
                emoji: selectedEmoji,
                appConfigs: selectedAppConfigs.isEmpty ? nil : selectedAppConfigs,
                urlConfigs: websiteConfigs.isEmpty ? nil : websiteConfigs,
                    isAIEnhancementEnabled: isAIEnhancementEnabled,
                    selectedPrompt: selectedPromptId?.uuidString,
                    selectedTranscriptionModelName: selectedTranscriptionModelName,
                    selectedLanguage: selectedLanguage,
                    // useScreenCapture: useScreenCapture,
                    selectedAIProvider: selectedAIProvider,
                    selectedAIModel: selectedAIModel,
                    isAutoSendEnabled: isAutoSendEnabled,
                    isDefault: isDefault
                )
        case .edit(let config):
            var updatedConfig = config
            updatedConfig.name = configName
            updatedConfig.emoji = selectedEmoji
            updatedConfig.isAIEnhancementEnabled = isAIEnhancementEnabled
            updatedConfig.selectedPrompt = selectedPromptId?.uuidString
            updatedConfig.selectedTranscriptionModelName = selectedTranscriptionModelName
            updatedConfig.selectedLanguage = selectedLanguage
            updatedConfig.appConfigs = selectedAppConfigs.isEmpty ? nil : selectedAppConfigs
            updatedConfig.urlConfigs = websiteConfigs.isEmpty ? nil : websiteConfigs
            // updatedConfig.useScreenCapture = useScreenCapture
            updatedConfig.isAutoSendEnabled = isAutoSendEnabled
            updatedConfig.selectedAIProvider = selectedAIProvider
            updatedConfig.selectedAIModel = selectedAIModel
            updatedConfig.isDefault = isDefault
            return updatedConfig
        }
    }
    
    private func loadInstalledApps() {
        // Get both user-installed and system applications
        let userAppURLs = FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask)
        let localAppURLs = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask)
        let systemAppURLs = FileManager.default.urls(for: .applicationDirectory, in: .systemDomainMask)
        let allAppURLs = userAppURLs + localAppURLs + systemAppURLs
        
        var allApps: [URL] = []
        
        func scanDirectory(_ baseURL: URL, depth: Int = 0) {
            // Prevent infinite recursion in case of circular symlinks
            guard depth < 5 else { return }
            
            guard let enumerator = FileManager.default.enumerator(
                at: baseURL,
                includingPropertiesForKeys: [.isApplicationKey, .isDirectoryKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles]
            ) else { return }
            
            for item in enumerator {
                guard let url = item as? URL else { continue }
                
                let resolvedURL = url.resolvingSymlinksInPath()
                
                // If it's an app, add it and skip descending into it
                if resolvedURL.pathExtension == "app" {
                    allApps.append(resolvedURL)
                    enumerator.skipDescendants()
                    continue
                }
                
                // Check if this is a symlinked directory we should traverse manually
                var isDirectory: ObjCBool = false
                if url != resolvedURL && 
                   FileManager.default.fileExists(atPath: resolvedURL.path, isDirectory: &isDirectory) && 
                   isDirectory.boolValue {
                    // This is a symlinked directory - traverse it manually
                    enumerator.skipDescendants()
                    scanDirectory(resolvedURL, depth: depth + 1)
                }
            }
        }
        
        // Scan all app directories
        for baseURL in allAppURLs {
            scanDirectory(baseURL)
        }
        
        installedApps = allApps.compactMap { url in
            guard let bundle = Bundle(url: url),
                  let bundleId = bundle.bundleIdentifier,
                  let name = (bundle.infoDictionary?["CFBundleName"] as? String) ??
                            (bundle.infoDictionary?["CFBundleDisplayName"] as? String) else {
                return nil
            }
            
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            return (url: url, name: name, bundleId: bundleId, icon: icon)
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    private func saveConfiguration() {
        
        
        let config = getConfigForForm()
        
        // Only validate when the user explicitly tries to save
        let validator = PowerModeValidator(powerModeManager: powerModeManager)
        validationErrors = validator.validateForSave(config: config, mode: mode)
        
        if !validationErrors.isEmpty {
            showValidationAlert = true
            return
        }
        
        // If validation passes, save the configuration
        switch mode {
        case .add:
            powerModeManager.addConfiguration(config)
        case .edit:
            powerModeManager.updateConfiguration(config)
        }
        
        // Handle default flag separately to ensure only one config is default
        if isDefault {
            powerModeManager.setAsDefault(configId: config.id)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}
