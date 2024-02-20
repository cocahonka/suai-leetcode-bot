extension StringX on String {
  String capitalize() => length > 0 ? this[0].toUpperCase() + substring(1) : this;

  String eachCapitalize([String separator = ' ']) => split(separator)
      .map(
        (word) => word.capitalize(),
      )
      .join(separator);
}
