package processing;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import pspdataprocessing.DataGroup;
import pspdataprocessing.DataHomogeneousSequence;
import pspdataprocessing.DataPattern;
import pspdataprocessing.DataSequence;
import pspdataprocessing.DataSequence.ActionOnPattern;
import pspdataprocessing.DataSequence.Mode;
import pspdataprocessing.DataSetGroupMap;
import pspdataprocessing.PSPTreeDataCorrector;
import pspdataprocessing.PSPTreeDataSet;
import pspdataprocessing.PSPTreeDataSet.ActionType;
import repicea.util.ObjectUtility;

public class QuebecPEPFormatting extends PSPTreeDataCorrector {
	
	
	public QuebecPEPFormatting(String filename) throws Exception {
		super(filename);
	}


	int manuallyRenumberFrom(DataSetGroupMap dataSetGroupMap, DataGroup group, int index) {
		String fieldName = "NO_ARBRE";
		PSPTreeDataSet ds = dataSetGroupMap.get(group);	
		for (int i = ds.getNumberOfObservations() - 1; i >= 0; i--) {
			Integer currentValue = (Integer) ds.getValueAt(i, fieldName);
			if (i >= index) {
				ds.correctValue(i, fieldName, currentValue + 1000, "manually renumbered", true, "status = C");
			}
		}
		return ds.getNumberOfObservations();
	}

	int acceptedAsIs(DataSetGroupMap dataSetGroupMap, DataGroup group) {
		String fieldName = "ETAT";
		PSPTreeDataSet ds = dataSetGroupMap.get(group);	
		Object currentValue = ds.getValueAt(0, fieldName);
		ds.correctValue(0, fieldName, currentValue, "accepted as is", true, "accepted as is");
		return ds.getNumberOfObservations();
	}

	int replaceThisStatusBy(DataSetGroupMap dataSetGroupMap, DataGroup group, int index, Object newStatus, String message) {
		String fieldName = "ETAT";
		PSPTreeDataSet ds = dataSetGroupMap.get(group);	
		if (ds == null) {
			System.out.println("This group was not found: " + group.toString());
		}
		ds.correctValue(index, fieldName, newStatus, message, true, "status = C");
		return ds.getNumberOfObservations();
	}

	int replaceThisIn1410By(DataSetGroupMap dataSetGroupMap, DataGroup group, int index, Object newIn1410, String message) {
		String fieldName = "IN_1410";
		PSPTreeDataSet ds = dataSetGroupMap.get(group);	
		if (ds == null) {
			System.out.println("This group was not found: " + group.toString());
		}
		ds.correctValue(index, fieldName, newIn1410, message, true, "status = C");
		return ds.getNumberOfObservations();
	}

	
	@Override
	public String performStatusCorrection(DataSetGroupMap dataSetGroupMap, boolean actionsEnabled) {
		List<Object> exclusions = new ArrayList<Object>();
		exclusions.add("NA");
		
		List<Object> terminalStatuses = new ArrayList<Object>();
		terminalStatuses.add("23");
		terminalStatuses.add("24");
		terminalStatuses.add("25");
		terminalStatuses.add("26");
		terminalStatuses.add("29");
		List<Object> deadStatuses = new ArrayList<Object>();
		deadStatuses.add("14");
		deadStatuses.add("15");
		deadStatuses.add("16");
		List<Object> forgottenDeadStatuses = new ArrayList<Object>();
		forgottenDeadStatuses.add("34");
		forgottenDeadStatuses.add("35");
		forgottenDeadStatuses.add("36");
		List<Object> recruitDeadStatuses = new ArrayList<Object>();
		recruitDeadStatuses.add("44");
		recruitDeadStatuses.add("45");
		recruitDeadStatuses.add("46");
		List<Object> renumberedDeadStatuses = new ArrayList<Object>();
		renumberedDeadStatuses.add("54");
		renumberedDeadStatuses.add("55");
		renumberedDeadStatuses.add("56");
		List<Object> aliveStatuses = new ArrayList<Object>();
		aliveStatuses.add("10");
		aliveStatuses.add("12");
		List<Object> forgottenStatuses = new ArrayList<Object>();
		forgottenStatuses.add("30");
		forgottenStatuses.add("32");
		List<Object> recruitStatuses = new ArrayList<Object>();
		recruitStatuses.add("40");
		recruitStatuses.add("42");
		List<Object> renumberedStatuses = new ArrayList<Object>();
		renumberedStatuses.add("50");
		renumberedStatuses.add("52");
		
		List<DataSequence> sequences = new ArrayList<DataSequence>();
		
		// NORMAL SEQUENCES
		ActionOnPattern action = new ActionOnPattern() {
			@Override
			protected void doAction(DataPattern pattern, Object...parms) {
				pattern.comment("status = C");
			}
		};
		DataSequence acceptableDataSequence = new DataSequence("Normal sequence", true, Mode.Total, action, sequences);

		List<Object> alives = new ArrayList<Object>();
		alives.addAll(aliveStatuses);
		alives.addAll(forgottenStatuses);
		alives.addAll(recruitStatuses);
		alives.addAll(renumberedStatuses);
		
		
		List<Object> possibleOutcomes;
		for (Object obj : alives) { // alive that stays alive or becomes dead
			possibleOutcomes = new ArrayList<Object>();
			possibleOutcomes.addAll(aliveStatuses);
			possibleOutcomes.addAll(forgottenDeadStatuses);
			possibleOutcomes.addAll(deadStatuses);
			possibleOutcomes.addAll(terminalStatuses);
			acceptableDataSequence.put(obj, DataSequence.convertListToMap(possibleOutcomes));
		}
		
		List<Object> allDead = new ArrayList<Object>();
		allDead.addAll(deadStatuses);
		allDead.addAll(forgottenDeadStatuses);
		allDead.addAll(recruitDeadStatuses);
		allDead.addAll(renumberedDeadStatuses);
		allDead.addAll(terminalStatuses);
		
		for (Object obj : allDead) {		// dead that stays dead
			possibleOutcomes = new ArrayList<Object>();
			possibleOutcomes.addAll(allDead);
			acceptableDataSequence.put(obj, DataSequence.convertListToMap(possibleOutcomes));
		}

		if (actionsEnabled) {
			// TWO TREES CONFOUNDED
			action = new ActionOnPattern() {
				@Override
				protected void doAction(DataPattern pattern, Object... parms) {
					int observationIndex = (Integer) parms[0];
					for (int i = 0; i < pattern.size(); i++) {
						if (i >= observationIndex + 1) {
							pattern.updateField(i, "NO_ARBRE", 1000, ActionType.Add);
							pattern.comment(i, "renumbered");
						} else {
							pattern.comment(i, "status = C");
						}
					}
				}
			};
			
			DataSequence twoDifferentTreesSequence = new DataSequence("two trees confounded", false, Mode.Partial, action, sequences);
			List<Object> deadOrMissingStatuses = new ArrayList<Object>();
			deadOrMissingStatuses.addAll(terminalStatuses);
			deadOrMissingStatuses.add("NA");
			for (Object obj : deadOrMissingStatuses) {
				possibleOutcomes = new ArrayList<Object>();
				possibleOutcomes.addAll(recruitStatuses);
				possibleOutcomes.addAll(recruitDeadStatuses);
				twoDifferentTreesSequence.put(obj, DataSequence.convertListToMap(possibleOutcomes));
			}

			// Trees that were called dead then alive and again alive
			action = new ActionOnPattern() {
				@Override
				protected void doAction(DataPattern pattern, Object... parms) {
					int observationIndex = (Integer) parms[0];
					for (int i = 0; i < pattern.size(); i++) {
						if (i == observationIndex) {
							pattern.updateField(i, "ETAT", "10", ActionType.Replace);
							pattern.comment(i, "status dead changed for alive");
						} else {
							pattern.comment(i, "status = C");
						}
					}
				}
			};
			DataSequence measurementErrorSequence1 = new DataSequence("measurement error", false, Mode.Partial, action, sequences);
			for (Object obj : deadStatuses) {	// dead followed by 2 alive statuses
				possibleOutcomes = new ArrayList<Object>();
				possibleOutcomes.addAll(aliveStatuses);
				Map<Object, Map> oMap = new HashMap<Object, Map>();
				oMap.put("10", DataSequence.convertListToMap(possibleOutcomes));
				measurementErrorSequence1.put(obj, oMap);
			}

			// Trees that were alive, then dead and then alive
			action = new ActionOnPattern() {
				@Override
				protected void doAction(DataPattern pattern, Object... parms) {
					int observationIndex = (Integer) parms[0];
					for (int i = 0; i < pattern.size(); i++) {
						if (i == observationIndex + 1) {
							pattern.updateField(i, "ETAT", "10", ActionType.Replace);
							pattern.comment(i, "status dead changed for alive");
						} else {
							pattern.comment(i, "status = C");
						}
					}
				}
			};
			DataSequence measurementErrorSequence2 = new DataSequence("measurement error", false, Mode.Partial, action, sequences);
			List<Object> aliveAndRecruits = new ArrayList<Object>();
			aliveAndRecruits.addAll(aliveStatuses);
			aliveAndRecruits.addAll(recruitStatuses);
			for (Object obj : aliveAndRecruits) {	// initially alive or recruit then dead and then alive again
				possibleOutcomes = new ArrayList<Object>();
				possibleOutcomes.add("10");
				possibleOutcomes.add("12");
				Map<Object, Map> oMap = new HashMap<Object, Map>();
				oMap.put("14", DataSequence.convertListToMap(possibleOutcomes));
				oMap.put("16", DataSequence.convertListToMap(possibleOutcomes));
				measurementErrorSequence2.put(obj, oMap);
			}
			
		}

		
		String outputString = dataSetGroupMap.patternize("ETAT", exclusions, sequences);
		int index = dataSet.getFieldNames().indexOf(DataPattern.JavaComments);
		dataSet.getFieldNames().set(index, DataPattern.JavaComments.concat("Status"));
		return outputString;

		
	}
	
	public int performManualIn1410Corrections(DataSetGroupMap dataSetGroupMap) {
		int nbManuallyChanged = 0;
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "N", "O"))) {
			nbManuallyChanged += replaceThisIn1410By(dataSetGroupMap, group, 0, "O", "Not in replaced by in");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "NA", "N", "O"))) {
			nbManuallyChanged += replaceThisIn1410By(dataSetGroupMap, group, 2, "N", "In replaced by not in");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "NA", "NA", "N", "O"))) {
			nbManuallyChanged += replaceThisIn1410By(dataSetGroupMap, group, 3, "N", "In replaced by not in");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "NA", "NA", "NA", "N", "O"))) {
			nbManuallyChanged += replaceThisIn1410By(dataSetGroupMap, group, 4, "N", "In replaced by not in");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "NA", "NA", "NA", "NA", "N", "O"))) {
			nbManuallyChanged += replaceThisIn1410By(dataSetGroupMap, group, 5, "N", "In replaced by not in");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "NA", "NA", "NA", "O", "N"))) {
			nbManuallyChanged += replaceThisIn1410By(dataSetGroupMap, group, 3, "N", "In replaced by not in");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "O", "N"))) {
			nbManuallyChanged += replaceThisIn1410By(dataSetGroupMap, group, 1, "O", "Not in replaced by in");
		}
		return nbManuallyChanged;
	}
	
	
	public int performManualStatusCorrections(DataSetGroupMap dataSetGroupMap) {
		int nbManuallyChanged = 0;
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10","10","10","30","10"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 3, "10", "Forgotten status replaced by alive status");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "10", "24", "10", "10"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 3);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "10", "24", "10"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 3);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "10", "26", "NA", "GA"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 3);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "10", "50", "10", "26"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "10", "NA", "GA"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "14", "14", "10", "26"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 1, "10", "Dead status replaced by alive");
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 2, "10", "Dead status replaced by alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "14", "14", "10"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 1, "10", "Dead status replaced by alive");
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 2, "10", "Dead status replaced by alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "14", "16", "10"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 3);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "14", "24", "NA", "GA"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 3);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "14", "NA", "GA"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		
		registerThisPatternAsAccepted(dataSetGroupMap, new DataPattern(null, "10", "24", "10", "10", "23"));
		
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "24", "10", "10"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "24", "10", "15"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "24", "10", "23"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "24", "10", "26"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "24", "10"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "24", "52", "23"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "24", "NA", "GA"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "24", "NA", "GM"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "24", "NA", "NA", "GA"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "25", "10", "10", "24"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "25", "10"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "25", "30", "10", "10"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 1, "10", "Intruder status replaced by alive");
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 2, "10", "Forgotten status replaced by alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "26", "10", "10", "10"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "26", "50", "10", "10"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "26", "NA", "GA"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "26", "NA", "GM"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "26", "NA", "NA", "GA"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "40", "10", "23"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 1);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "40", "10"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 1);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "40", "16"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 1, "10", "Recruit status replaced by alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "10", "NA", "23"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 1, "14", "NA status replaced by dead");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "14", "10", "14", "14", "23"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "10", "Dead status replaced by alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "14", "10", "14", "14"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "10", "Dead status replaced by alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "14", "10", "14", "16"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "10", "Dead status replaced by alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "14", "10", "14", "23"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "10", "Dead status replaced by alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "14", "10", "14", "24"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "10", "Dead status replaced by alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "14", "10", "14"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "10", "Dead status replaced by alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "14", "10", "23"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "10", "Dead status replaced by alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "14", "10", "24"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "10", "Dead status replaced by alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "14", "10", "26"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "10", "Dead status replaced by alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "14", "12", "12", "12", "24"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "12", "Dead status replaced by windfall");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "14", "12", "23"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "12", "Dead status replaced by windfall");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "14", "12", "24"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "12", "Dead status replaced by windfall");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "14", "14", "10"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "10", "Dead status replaced by alive");
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 1, "10", "Dead status replaced by alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "14", "14", "14", "10", "23"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "10", "Dead status replaced by alive");
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 1, "10", "Dead status replaced by alive");
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 2, "10", "Dead status replaced by alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "14", "24", "10", "10", "10"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "14", "24", "10", "10"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "14", "24", "NA", "GA"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "14", "24", "NA", "GM"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "14", "26", "NA", "GM"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "16", "10"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 1);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "34", "10", "10"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "30", "Forgotten dead status replaced by forgotten alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "34", "10", "15"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "30", "Forgotten dead status replaced by forgotten alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "34", "10", "25"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "30", "Forgotten dead status replaced by forgotten alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "34", "10"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "30", "Forgotten dead status replaced by forgotten alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "40", "10", "40", "10"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 2, "10", "Recruit status replaced by alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "40", "14", "14", "12", "23"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 1, "12", "Dead status replaced by windfall");
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 2, "12", "Dead status replaced by windfall");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "40", "23", "10", "10"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 1, "10", "Missing status replaced by alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "40", "26", "NA", "NA", "GA"))) {
			nbManuallyChanged += manuallyRenumberFrom(dataSetGroupMap, group, 2);
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "40", "30", "10"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 1, "10", "Forgotten status replaced by alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "40", "40", "10"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 1, "10", "Recruit status replaced by alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "40", "40", "24"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 1, "10", "Recruit status replaced by alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "40", "44", "10"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 1, "10", "Dead recruit status replaced by alive");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "40", "44", "24"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 1, "14", "Dead recruit status replaced by dead");
		}
		
		registerThisPatternAsAccepted(dataSetGroupMap, new DataPattern(null, "40", "NA", "GM"));
		
		registerThisPatternAsAccepted(dataSetGroupMap, new DataPattern(null, "42", "GM"));
		
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "44", "10", "10"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "40", "Dead recruit status replaced by recruit");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "44", "10", "15"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "40", "Dead recruit status replaced by recruit");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "44", "10", "23"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "40", "Dead recruit status replaced by recruit");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "44", "10"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "40", "Dead recruit status replaced by recruit");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "46", "10"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "40", "Dead recruit status replaced by recruit");
		}
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(new DataPattern(null, "54", "10"))) {
			nbManuallyChanged += replaceThisStatusBy(dataSetGroupMap, group, 0, "50", "Dead renumbeered status replaced by alive renumbered");
		}
		
		registerThisPatternAsAccepted(dataSetGroupMap, new DataPattern(null, "GM"));
		
		registerThisPatternAsAccepted(dataSetGroupMap, new DataPattern(null, "GV", "40"));
		
		registerThisPatternAsAccepted(dataSetGroupMap, new DataPattern(null, "NA", "GA"));
		
		registerThisPatternAsAccepted(dataSetGroupMap, new DataPattern(null, "NA", "GM", "GM"));
		
		registerThisPatternAsAccepted(dataSetGroupMap, new DataPattern(null, "NA", "GM"));
		
		registerThisPatternAsAccepted(dataSetGroupMap, new DataPattern(null, "NA", "NA", "GA", "GA"));
		
		registerThisPatternAsAccepted(dataSetGroupMap, new DataPattern(null, "NA", "NA", "GA"));
		
		registerThisPatternAsAccepted(dataSetGroupMap, new DataPattern(null, "NA", "NA", "GM"));
		
		registerThisPatternAsAccepted(dataSetGroupMap, new DataPattern(null, "NA", "NA", "NA", "GA"));
		
		registerThisPatternAsAccepted(dataSetGroupMap, new DataPattern(null, "NA", "NA", "NA", "GM"));
	
		registerThisPatternAsAccepted(dataSetGroupMap, new DataPattern(null, "NA", "NA", "NA", "NA", "GA"));
		
		return nbManuallyChanged;
	}

	
	private void registerThisPatternAsAccepted(DataSetGroupMap dataSetGroupMap, DataPattern acceptedPattern) {
		for (DataGroup group : dataSetGroupMap.getGroupsMatchingThisPattern(acceptedPattern)) {
			acceptedAsIs(dataSetGroupMap, group);
		}
		registerAcceptedPattern(acceptedPattern);
	}
	 
	
	@Override
	public String performSpeciesCorrection(DataSetGroupMap dataSetGroupMap, boolean actionsEnabled) {
		List<Object> exclusions = new ArrayList<Object>();
		exclusions.add("NA");
		
		List<DataSequence> sequences = new ArrayList<DataSequence>();

		
		ActionOnPattern action = new ActionOnPattern() {
			@Override
			protected void doAction(DataPattern pattern, Object... parms) {
				Object species = parms[0];
				for (int i = 0; i < pattern.size(); i++) {
					if (!pattern.get(i).equals(species)) {
						pattern.updateField(i, "ESSENCE", species, ActionType.Replace);
						pattern.comment(i, "species set according to homogeneous method");
					}
				}
			}
		};
		
		DataHomogeneousSequence homogeneousSequence = new DataHomogeneousSequence("Homogeneous", action, sequences) {
			@Override
			protected Object doesPartOfPatternFitThisSequence(DataPattern pattern, List<Object> exclusions) {
				List<Object> clone = pattern.getCleanPattern(exclusions);
				if (clone.isEmpty()) {
					return null;
				} else if (clone.size() == 1) {
					return clone.get(0);
				} else {
					for (int i = 1; i < clone.size(); i++) {
						if (!clone.get(i).equals(clone.get(i - 1))) {
							return null;
						}
					}
					return clone.get(0);
				}
			}
		};
		
		action = new ActionOnPattern() {
			@Override
			protected void doAction(DataPattern pattern, Object... parms) {
				Object species = parms[0];
				for (int i = 0; i < pattern.size(); i++) {
					if (!pattern.get(i).equals(species)) {
						pattern.updateField(i, "ESSENCE", species, ActionType.Replace);
						pattern.comment(i, "species set to according to emerging method");
					}
				}
			}

		};

		DataHomogeneousSequence emergingObjectSequence = new DataHomogeneousSequence("Emerging object", action, sequences) {
			@Override
			protected Object doesPartOfPatternFitThisSequence(DataPattern pattern, List<Object> exclusions) {
				DataPattern clone = pattern.getCleanPattern(exclusions);
				Map<Object, Double> rankingMap = new HashMap<Object, Double>();
				for (int i = 0; i < clone.size(); i++) {
					Object obj = clone.get(i);
					double previousValue = 0d;
					if (rankingMap.containsKey(obj)) {
						previousValue = rankingMap.get(obj);
					} 
					rankingMap.put(obj, previousValue + i * .5 + 1);
				}
				double maxValue = 1d;
				Object winningObject = null;
				for (Object obj : rankingMap.keySet()) {
					double rank = rankingMap.get(obj);
					if (rank > maxValue + 1) {
						maxValue = rank;
						winningObject = obj;
					}
				}
				return winningObject;
			}
		};
		
		action = new ActionOnPattern() {
			@Override
			protected void doAction(DataPattern pattern, Object... parms) {
				Object species = parms[0];
				for (int i = 0; i < pattern.size(); i++) {
					if (!pattern.get(i).equals(species)) {
						pattern.updateField(i, "ESSENCE", species, ActionType.Replace);
						pattern.comment(i, "species set according to last-but-similar method");
					}
				}
			}

		};
		DataHomogeneousSequence lastButSimilarSequence = new DataHomogeneousSequence("Last but similar", action, sequences) {
			@Override
			protected Object doesPartOfPatternFitThisSequence(DataPattern pattern, List<Object> exclusions) {
				DataPattern clone = pattern.getCleanPattern(exclusions);
				DataPattern subPattern = clone.getSubDataPattern(0, 2);
				
				if (subPattern.isEmpty()) {
					return null;
				} else if (subPattern.size() == 1) {
					return clone.get(0);
				} else {
					for (int i = 1; i < subPattern.size(); i++) {
						if (!subPattern.get(i).equals(subPattern.get(i - 1))) {
							return null;
						}
					}
					return clone.get(0);
				}
			}
		};

		action = new ActionOnPattern() {
			@Override
			protected void doAction(DataPattern pattern, Object... parms) {
				Object species = parms[0];
				for (int i = 0; i < pattern.size(); i++) {
					if (!pattern.get(i).equals(species)) {
						pattern.updateField(i, "ESSENCE", species, ActionType.Replace);
						pattern.comment(i, "species set according to last-in-sequence method");
					}
				}
			}

		};		
		
		DataHomogeneousSequence lastInSequence = new DataHomogeneousSequence("Last in sequence", action, sequences) {
			@Override
			protected Object doesPartOfPatternFitThisSequence(DataPattern pattern, List<Object> exclusions) {
				DataPattern clone = pattern.getCleanPattern(exclusions);
				if (clone.size() > 0) {
					return clone.get(clone.size() - 1);
				} else {
					return null;
				}
			}
		};
		
		String outputString = dataSetGroupMap.patternize("ESSENCE", exclusions, sequences);
		int index = dataSet.getFieldNames().indexOf(DataPattern.JavaComments);
		dataSet.getFieldNames().set(index, DataPattern.JavaComments.concat("Species"));
		return outputString;
	}

	public String performIn1410Correction(DataSetGroupMap dataSetGroupMap, boolean actionsEnabled) {
		List<Object> exclusions = new ArrayList<Object>();
		exclusions.add("NA");
		
		List<DataSequence> sequences = new ArrayList<DataSequence>();
		
		// NORMAL SEQUENCES
		ActionOnPattern action = new ActionOnPattern() {
			@Override
			protected void doAction(DataPattern pattern, Object...parms) {
				pattern.comment("status = C");
			}
		};
		DataSequence acceptableDataSequence = new DataSequence("Normal sequence", true, Mode.Total, action, sequences);
		acceptableDataSequence.put("O", DataSequence.convertListToMap(Arrays.asList(new String[] {"O"})));
		acceptableDataSequence.put("N", DataSequence.convertListToMap(Arrays.asList(new String[] {"N"})));

		String outputString = dataSetGroupMap.patternize("IN_1410", exclusions, sequences);
		int index = dataSet.getFieldNames().indexOf(DataPattern.JavaComments);
		dataSet.getFieldNames().set(index, DataPattern.JavaComments.concat("In1410"));
		return outputString;
	}
	
	
	
	public static void main(String[] args) throws Exception {
		String appRootPath = ObjectUtility.getTrueRootPath(QuebecPEPFormatting.class);
		String trueRootPath = new File(appRootPath).getParent();
		String filename = trueRootPath + File.separator + "treesBeforeCorrection.csv";

		System.out.println("Importing data in Java...");
		QuebecPEPFormatting formatter = new QuebecPEPFormatting(filename);
		formatter.setFieldnamesForSplitting("newID_PE", "NO_ARBRE");
		formatter.setFieldnamesForSorting("year");
		DataSetGroupMap dsgm = formatter.splitAndSort();
		
		System.out.println("Performing automated status correction (first round)...");
		System.out.println(formatter.performStatusCorrection(dsgm, true));
		System.out.println("Performing manual status correction");
		formatter.performManualStatusCorrections(dsgm);
		dsgm = formatter.splitAndSort();	// we redefine the DataSetGroupMap instance after running the automatic and manuel corrections
		System.out.println("Performing automated status correction (second round)...");
		System.out.println(formatter.performStatusCorrection(dsgm, true));

		dsgm = formatter.splitAndSort();
		System.out.println("Performing automated species correction (first round)");
		System.out.println(formatter.performSpeciesCorrection(dsgm, true));

		dsgm = formatter.splitAndSort();
		System.out.println("Performing automated in1410 correction (first round)");
		System.out.println(formatter.performIn1410Correction(dsgm, true));
		System.out.println("Performing manual in1410 correction");
		formatter.performManualIn1410Corrections(dsgm);
		dsgm = formatter.splitAndSort();	// we redefine the DataSetGroupMap instance after running the automatic and manuel corrections
		System.out.println("Performing automated in1410 correction (second round)...");
		System.out.println(formatter.performStatusCorrection(dsgm, true));
		
//		System.out.println(dsgm.displayDataGroupsWithThisPattern("O","N"));
		
		String exportCorrectedFilename = trueRootPath + File.separator + "treesCorrected.csv";
		dsgm.save(exportCorrectedFilename);
		System.exit(0);
	}

}
