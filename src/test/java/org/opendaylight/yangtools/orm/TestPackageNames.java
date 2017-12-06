package org.opendaylight.yangtools.orm;

import java.util.Map;
import java.util.TreeMap;

import org.junit.Assert;
import org.junit.Test;
import org.opendaylight.yangtools.orm.utils.PackageUtils;

public class TestPackageNames {
	
	@Test
	public void testPackageName() {
		
		System.out.println(Map.class.getName());
		System.out.println(Map.class.getSimpleName());
		System.out.println(Map.class.getCanonicalName());
		
	}
	
	@Test
	public void testPackageNameGenerations() {
		
		Map<String, String> imports = new TreeMap<>();
		Assert.assertTrue(PackageUtils.getImportedName(Map.class, imports).equals("Map"));
		Assert.assertTrue(PackageUtils.getImportedName(Map.class, imports).equals("Map"));
		
	}
	
	@Test
	public void testPackageNameForParameterizedType() {
		
		Map<String, String> imports = new TreeMap<>();
		System.out.println(PackageUtils.getImportedName(imports.getClass(), imports));
		Assert.assertTrue(PackageUtils.getImportedName(imports.getClass(), imports).equals("TreeMap"));
		Assert.assertTrue(PackageUtils.getImportedName(imports.getClass(), imports).equals("TreeMap"));
		
	}

}
