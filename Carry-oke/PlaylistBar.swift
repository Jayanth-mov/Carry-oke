// MARK: - Playlist Bar (Liquid Glass)
struct PlaylistBar: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Playlist is empty.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                PlayButton(systemName: "play.fill")
                PlayButton(systemName: "forward.end.fill")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .modifier(GlassEffectModifier(tintColor: Color(hex: "F87060").opacity(0.2), shape: .capsule))
    }
}