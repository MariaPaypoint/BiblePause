//  Created by Maria Novikova on 24.12.2022.
//  Сделано по статье https://betterprogramming.pub/swiftui-create-a-fancy-toast-component-in-10-minutes-e6bae6021984

import SwiftUI

struct FancyToastView: View {
    var type: FancyToastStyle
    var title: String
    var message: String
    var onCancelTapped: (() -> Void)
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Image(systemName: type.iconFileName)
                    .foregroundColor(type.themeLeftColor)
                    .padding(.top, 2)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(title)
                            .font(.title3.weight(.medium))
                            .foregroundColor(type.themeTextColor)
                        Spacer(minLength: 10)
                        Button {
                            onCancelTapped()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(type.themeBorderColor)
                        }
                    }
                    .padding(.bottom, -3) // без паддинга как будто -10
                    Text(message)
                        .font(.subheadline.weight(.light))
                        .foregroundColor(type.themeTextColor)
                }
                .padding(.leading, 5)
            }
            .padding(globalBasePadding)
        }
        
        .overlay(
            Rectangle()
                .fill(type.themeLeftColor)
                .frame(width: 6)
                .clipped()
            
            , alignment: .leading
        )
        .cornerRadius(10)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(type.themeBorderColor, lineWidth: 0.5)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(type.themeBgColor))
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding(.horizontal, 16)
    }
}

struct FancyToastView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            FancyToastView(
                type: .success,
                title: "Успех",
                message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. ") {}
            
            FancyToastView(
                type: .error,
                title: "Error",
                message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. ") {}
            
            FancyToastView(
                type: .info,
                title: "Info",
                message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. ") {}
            
            FancyToastView(
                type: .warning,
                title: "Предупреждение",
                message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. ") {}
        }
    }
}
