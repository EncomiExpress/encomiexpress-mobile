class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String telefono;
  final String rol;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.rol,
  });

  bool get isAdmin => rol.toLowerCase() == 'admin' || rol.toLowerCase() == 'administrador';
  bool get isConductor => rol.toLowerCase() == 'conductor';

  Usuario copyWith({
    String? id,
    String? nombre,
    String? email,
    String? telefono,
    String? rol,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      rol: rol ?? this.rol,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'rol': rol,
    };
  }
}