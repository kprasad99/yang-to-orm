package org.opendaylight.yangtools.orm.utils;

import java.util.Comparator;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.TreeSet;
import java.util.function.Supplier;
import java.util.stream.Collectors;

public class PackageUtils {

	public static final Comparator<String> COMPARATOR = (o1, o2) -> o1.compareTo(o2);
	public static Supplier<TreeSet<String>> supplier = () -> new TreeSet<>(COMPARATOR);

	public static String getImportedName(Class<?> cls, Map<String, String> imports) {
		if (cls.getName().startsWith("java.lang")) {
			imports.put(cls.getSimpleName(), cls.getCanonicalName());
			return cls.getSimpleName();
		}
		if (imports.containsKey(cls.getSimpleName())) {
			if (imports.get(cls.getSimpleName()).equals(cls.getCanonicalName())) {
				return cls.getSimpleName();
			} else {
				// already a type with same name exists return fully qualified name
				return cls.getCanonicalName();
			}
		} else {
			imports.put(cls.getSimpleName(), cls.getCanonicalName());
		}
		return cls.getSimpleName();
	}

	public static Set<String> getSortedImports(Map<String, String> imports) {
		return imports.entrySet().stream().map(Entry::getValue).sorted(COMPARATOR)
				.collect(Collectors.toCollection(supplier));
	}

}
