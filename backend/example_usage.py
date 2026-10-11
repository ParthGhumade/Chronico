import logging
import sys
from pathlib import Path

# Add project root to sys.path if needed
sys.path.insert(0, str(Path(__file__).parent.parent))

from backend.critic import run_critic_agent
from backend.models import Context, Event, Photo, School
from backend.pdf_renderer import generate_pdf_report
from backend.pipeline import run_writer_verifier_pipeline
from backend.verifier import run_verifier_agent
from backend.writer import run_writer_agent

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")


def main():
    sample_context = Context(
        school=School(
            name="श्री छत्रपती शिवाजी विद्यालय",
            address="पुणे, महाराष्ट्र",
            principal="डॉ. ए. बी. पाटील",
            signatory="उपप्राचार्य एम. एन. देशपांडे",
        ),
        event=Event(
            id="evt_001",
            title="वार्षिक स्नेहसंमेलन २०२६",
            date="2026-01-25",
            venue="शाळा प्रांगण",
            category="सांस्कृतिक",
        ),
        photos=[
            Photo(
                id="img_01",
                description="विद्यार्थी सांस्कृतिक नृत्य सादर करत आहेत",
                ocr=None,
            )
        ],
        raw_narration="२५ जानेवारी रोजी शाळेत वार्षिक स्नेहसंमेलन उत्साहात पार पडले. कार्यक्रमाचे उद्घाटन डॉ. पाटील यांच्या हस्ते झाले. विद्यार्थ्यांनी विविध सांस्कृतिक कार्यक्रम सादर केले.",
    )

    print("=== Chronico V0: Complete Multi-Agent AI Pipeline Test ===")

    # 1. Direct Verifier test with an intentionally hallucinated draft
    print("\n--- 1. Testing Verifier Agent (Hallucination Detection) ---")
    hallucinated_draft = """
    दिनांक २५ जानेवारी २०२६ रोजी श्री छत्रपती शिवाजी विद्यालय, पुणे येथे वार्षिक स्नेहसंमेलन उत्साहात पार पडले.
    कार्यक्रमाचे उद्घाटन डॉ. ए. बी. पाटील यांच्या हस्ते झाले.
    या प्रसंगी प्रमुख पाहुणे म्हणून शिक्षण मंत्री उपस्थित होते आणि त्यांनी १ लाख रुपयांचे बक्षीस जाहीर केले.
    विद्यार्थ्यांनी नृत्य व नाटिका सादर केल्या.
    """

    print("Evaluating hallucinated draft...")
    try:
        verifier_result = run_verifier_agent(sample_context, hallucinated_draft)
        print(f"Status: {verifier_result.status}")
        print("Detected Issues / Comments:")
        for issue in verifier_result.issues:
            print(f"  - {issue}")
    except Exception as e:
        print(f"Error testing Verifier Agent: {e}")

    # 2. Direct Critic test with unpolished / informal draft
    print("\n--- 2. Testing Critic Agent (Grammar & Structure Polish) ---")
    unpolished_draft = """
    २५ जानेवारी २०२६ ला आपल्या श्री छत्रपती शिवाजी विद्यालय पुणे मध्ये वार्षिक स्नेहसंमेलन झाले. 
    डॉ पाटील यांनी कार्यक्रमाचे उद्घघाटन केले. नंतर पोरांनी छान नृत्य व गाणी गायली.
    """
    print("Polishing draft with Critic Agent...")
    try:
        critic_result = run_critic_agent(unpolished_draft, sample_context)
        print("\nOriginal Unpolished Draft:\n", unpolished_draft.strip())
        print("\nCritic Polished Output:\n", critic_result)
    except Exception as e:
        print(f"Error testing Critic Agent: {e}")

    # 3. Full Pipeline Test (Writer -> Verifier Retry Loop -> Critic Polish)
    print("\n--- 3. Testing Full Writer -> Verifier -> Critic Pipeline ---")
    try:
        pipeline_result = run_writer_verifier_pipeline(sample_context, max_retries=3, enable_critic=True)
        print("\n=== Final Pipeline Result ===")
        print(f"Approved: {pipeline_result.approved}")
        print(f"Total Iterations: {pipeline_result.iterations}")
        print("\nVerification History:")
        for idx, res in enumerate(pipeline_result.verification_history, start=1):
            print(f" Attempt {idx}: status={res.status}, issues={res.issues}")
        print("\nFinal Verified & Polished Report:\n")
        print(pipeline_result.final_report)
        print("=" * 50)
        
        # 4. PDF Generation Test
        print("\n--- 4. Testing PDF Generation ---")
        pdf_output_path = "backend/generated_reports/report_001.pdf"
        generate_pdf_report(pipeline_result.final_report, sample_context, pdf_output_path)
        print(f"PDF successfully generated at: {pdf_output_path}")

        # 5. Single I/O API Test (Only raw narration provided - no manual Context construction)
        print("\n--- 5. Testing Single I/O API (Narration In -> Report & PDF Out) ---")
        from backend.pipeline import generate_report

        single_io_response = generate_report(
            narration="२६ जानेवारी रोजी शाळेत ७७ वा प्रजासत्ताक दिन साजरा करण्यात आला. ध्वजारोहण सरपंच यांच्या हस्ते झाले. विद्यार्थ्यांनी देशभक्तीपर गीते गायली.",
            photos=[],
        )
        print(f"Single I/O Success: {single_io_response.success}")
        print(f"Extracted Event Title: {single_io_response.event.title}")
        print(f"Extracted Event Date: {single_io_response.event.date}")
        print(f"Generated PDF Path: {single_io_response.pdf_path}")
        print(f"Report Text Preview:\n{single_io_response.report_text[:200]}...")

    except Exception as e:
        print(f"Error running pipeline: {e}")


if __name__ == "__main__":
    main()

