//
//  EventCreateCategoryPickerSheet.swift
//  SOCIETY
//

import SwiftUI

struct EventCreateCategoryPickerSheet: View {
    let categories: [EventCategory]
    @Binding var selectedCategory: EventCategory?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(categories) { category in
                Button {
                    selectedCategory = category
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: category.iconIdentifier)
                            .font(.system(size: 18))
                            .foregroundStyle(category.accentColor)
                            .frame(width: 28)
                        Text(category.name)
                            .font(.system(size: 17))
                            .foregroundStyle(AppColors.primaryText)
                        Spacer()
                        if selectedCategory?.id == category.id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(category.accentColor)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
    }
}
