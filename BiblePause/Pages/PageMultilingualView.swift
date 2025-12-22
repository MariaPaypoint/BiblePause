import UniformTypeIdentifiers
import SwiftUI

struct PageMultilingualView: View {
    
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var editingStepIndex: Int? = nil
    @State private var showConfigSheet: Bool = false
    @State private var tempStep: MultilingualStep = MultilingualStep(type: .read)
    
    @State private var toast: FancyToast? = nil
    @State private var draggedStep: MultilingualStep? = nil
    
    var body: some View {
        ZStack {
            // Background
            Color("DarkGreen")
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // MARK: Header
                HStack {
                    MenuButtonView()
                        .environmentObject(settingsManager)
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("multilingual.title".localized) // Localized
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("multilingual.subtitle".localized) // Localized
                            .font(.caption)
                            .foregroundColor(Color("Marigold"))
                    }
                    
                    Spacer()
                    
                    Button {
                        // TODO: Open saved configurations?
                    } label: {
                        Image(systemName: "folder")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, globalBasePadding)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                // MARK: Read By Picker
                HStack {
                    Text("multilingual.read_by".localized) // Localized
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Menu {
                        Picker("multilingual.read_by".localized, selection: $settingsManager.multilingualReadUnitRaw) {
                            ForEach(MultilingualReadUnit.allCases, id: \.self) { unit in
                                Text(unit.localized).tag(unit.rawValue)
                            }
                        }
                    } label: {
                        HStack {
                            Text(settingsManager.multilingualReadUnit.localized)
                            Image(systemName: "chevron.down")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, globalBasePadding)
                .padding(.bottom, 20) // Extra spacing
                
                // MARK: Steps List
                // MARK: Steps List
                List {
                    ForEach(Array(settingsManager.multilingualSteps.enumerated()), id: \.element.id) { index, step in
                        stepRow(index: index, step: step)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 5, leading: globalBasePadding, bottom: 5, trailing: 16))
                    }
                    .onMove(perform: moveSteps)
                }
                .listStyle(.plain)
                .environment(\.editMode, .constant(.active))
                .scrollContentBackground(.hidden) 
                .environment(\.colorScheme, .dark) // Force dark mode controls for visibility 
                
                // MARK: Action Buttons
                HStack(spacing: 15) {
                    // Add Read Step using styled button
                    Button {
                        addNewReadStep()
                    } label: {
                        HStack {
                            Image(systemName: "book.fill")
                            Text("multilingual.add_read_step".localized)
                        }
                        .font(.subheadline)
                        .foregroundColor(Color("Marigold"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color("Mustard").opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5]))
                        )
                        .background(Color("DarkGreen").brightness(0.05).cornerRadius(10))
                    }
                    
                    // Add Pause Step
                    Button {
                        addNewPauseStep()
                    } label: {
                        HStack {
                            Image(systemName: "hourglass")
                            Text("multilingual.add_pause_step".localized)
                        }
                        .font(.subheadline)
                        .foregroundColor(Color("Marigold"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color("Mustard").opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5]))
                        )
                        .background(Color("DarkGreen").brightness(0.05).cornerRadius(10))
                    }
                }
                .padding(.horizontal, globalBasePadding)
                .padding(.vertical, 10)
                
                // MARK: Save & Read Button
                Button {
                    settingsManager.saveMultilingualSteps()
                    settingsManager.selectedMenuItem = .read // Or should we trigger a specific multilingual read mode?
                    // For now, assume global state handles it if I knew where.
                    // But maybe I should set some flag "isMultilingualMode = true"
                    // The user image says "Save & Read".
                    // I will just navigate to read page.
                    settingsManager.showMenu = false // Ensure menu is closed
                } label: {
                    Text("multilingual.save_and_read".localized)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("Marigold"))
                        .cornerRadius(12)
                }
                .padding(.horizontal, globalBasePadding)
                .padding(.bottom, 30)
                .padding(.top, 10)
            }
            
            // Menu layer (required for MenuButtonView to work correctly with logic)
            MenuView()
                .environmentObject(settingsManager)
                .offset(x: settingsManager.showMenu ? 0 : -UIScreen.main.bounds.width)
        }
        .toastView(toast: $toast)
        .sheet(isPresented: $showConfigSheet) {
            MultilingualConfigSheet(step: tempStep) { newStep in
                if let index = editingStepIndex {
                    settingsManager.multilingualSteps[index] = newStep
                } else {
                    settingsManager.multilingualSteps.append(newStep)
                }
                settingsManager.saveMultilingualSteps()
            }
            .environmentObject(settingsManager)
        }
    }
    
    // MARK: Drop Delegate Removed - using native List EditMode

    
    // MARK: Rows
    @ViewBuilder
    func stepRow(index: Int, step: MultilingualStep) -> some View {
        HStack(spacing: 12) {
            
            // Icon
            if step.type == .read {
                Image(systemName: "book.fill")
                    .foregroundColor(Color("Marigold"))
                    .font(.title2)
                    .frame(width: 30)
            } else {
                Image(systemName: "hourglass")
                    .foregroundColor(Color("Marigold"))
                    .font(.title2)
                    .frame(width: 30)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                if step.type == .read {
                    Text(step.translationName.isEmpty ? "multilingual.select_translation".localized : step.translationName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(step.languageName.isEmpty ? step.languageCode : step.languageName) \(step.voiceName.isEmpty ? "" : "• " + step.voiceName)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                } else {
                    Text("multilingual.pause".localized)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(String(format: "%0.0f", step.pauseDuration)) " + "multilingual.seconds".localized)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Controls
            if step.type == .pause {
                HStack(spacing: 0) {
                    Button {
                        if settingsManager.multilingualSteps[index].pauseDuration > 1 {
                            settingsManager.multilingualSteps[index].pauseDuration -= 1
                        }
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 30, height: 30)
                            .contentShape(Rectangle())
                    }
                    
                    Divider().frame(height: 20).background(Color.white.opacity(0.3))
                    
                    Button {
                        settingsManager.multilingualSteps[index].pauseDuration += 1
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 30, height: 30)
                            .contentShape(Rectangle())
                    }
                }
                .background(Color.white.opacity(0.1))
                .cornerRadius(5)
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.white)
            }
            
            // Edit / Drag / Delete
            // Native reorder handle will appear automatically in EditMode on the right.
            
            Button {
                withAnimation {
                    deleteStep(at: index)
                }
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color("DarkGreen").brightness(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if step.type == .read {
                editReadStep(index: index)
            }
        }
    }
    
    // MARK: Logic
    func addNewReadStep() {
        tempStep = MultilingualStep(type: .read)
        // Set defaults from current settings if needed
        editingStepIndex = nil
        showConfigSheet = true
    }
    
    func editReadStep(index: Int) {
        tempStep = settingsManager.multilingualSteps[index]
        editingStepIndex = index
        showConfigSheet = true
    }
    
    func addNewPauseStep() {
        let step = MultilingualStep(type: .pause, pauseDuration: 2.0)
        withAnimation {
            settingsManager.multilingualSteps.append(step)
        }
        settingsManager.saveMultilingualSteps()
    }
    
    func deleteSteps(at offsets: IndexSet) {
        settingsManager.multilingualSteps.remove(atOffsets: offsets)
        settingsManager.saveMultilingualSteps()
    }
    
    func deleteStep(at index: Int) {
        settingsManager.multilingualSteps.remove(at: index)
        settingsManager.saveMultilingualSteps()
    }
    
    func moveSteps(from source: IndexSet, to destination: Int) {
        settingsManager.multilingualSteps.move(fromOffsets: source, toOffset: destination)
        settingsManager.saveMultilingualSteps()
    }
}
